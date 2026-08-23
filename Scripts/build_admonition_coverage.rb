#!/usr/bin/env ruby

require "csv"
require "digest"
require "json"
require "rexml/document"
require "rexml/xpath"

abort "Usage: ruby Scripts/build_admonition_coverage.rb /path/to/swift_book.epub" unless ARGV.length == 1

epub_path = File.expand_path(ARGV.fetch(0))
abort "EPUB not found: #{epub_path}" unless File.file?(epub_path)

project_root = File.expand_path("..", __dir__)
catalog_root = File.join(project_root, "Content/SourceCatalog/swift-6.4-beta")
manifest = JSON.parse(File.read(File.join(catalog_root, "source-manifest.json")))
heading_rows = CSV.read(File.join(catalog_root, "coverage-matrix.csv"), headers: true)
headings_by_reference = heading_rows.group_by { |row| row.fetch("source_reference") }
catalog = JSON.parse(
  File.read(File.join(project_root, "Swift Learn/Data/Content/swift-6.4-beta-foundations.json"))
)
catalog_lesson_ids = catalog.fetch("levels").flat_map { |level| level.fetch("lessons") }
  .map { |lesson| lesson.fetch("id") }

parent_heading_reuse = {
  "LanguageGuide/CollectionTypes.xhtml#collection-types" => ["swift.generics.type"],
  "LanguageGuide/Closures.xhtml#closures" => ["swift.closures.capture"],
  "LanguageGuide/ClassesAndStructures.xhtml#structures-and-classes" => ["swift.types.instances"],
  "LanguageGuide/ClassesAndStructures.xhtml#Comparing-Structures-and-Classes" => ["swift.concurrency.actor"],
  "LanguageGuide/OptionalChaining.xhtml#optional-chaining" => ["swift.optional-chaining.alternative"],
  "LanguageGuide/AccessControl.xhtml#access-control" => ["swift.access.levels"]
}.freeze

new_lesson_candidates = {
  "LanguageGuide/StringsAndCharacters.xhtml#strings-and-characters" => "swift.strings.foundation-bridging",
  "LanguageGuide/CollectionTypes.xhtml#Arrays" => "swift.arrays.foundation-bridging",
  "LanguageGuide/CollectionTypes.xhtml#Sets" => "swift.sets.foundation-bridging",
  "LanguageGuide/CollectionTypes.xhtml#Dictionaries" => "swift.dictionaries.foundation-bridging",
  "LanguageGuide/Initialization.xhtml#Setting-Initial-Values-for-Stored-Properties" => "swift.initialization.observer-bypass",
  "LanguageGuide/ErrorHandling.xhtml#error-handling" => "swift.errors.nserror-interoperability",
  "LanguageGuide/ErrorHandling.xhtml#Handling-Errors" => "swift.errors.no-stack-unwinding",
  "LanguageGuide/Concurrency.xhtml#concurrency" => "swift.concurrency.thread-independence",
  "LanguageGuide/Extensions.xhtml#extensions" => "swift.extensions.no-overrides"
}.freeze

rows = []

manifest.fetch("documents").each do |document|
  inventory = document.fetch("admonitions")
  next if inventory.empty?

  xhtml = IO.popen(
    ["unzip", "-p", epub_path, "OEBPS/#{document.fetch("sourceFile")}"],
    &:read
  )
  parsed = REXML::Document.new(xhtml)
  notes = REXML::XPath.match(
    parsed,
    "//*[contains(concat(' ', normalize-space(@class), ' '), ' aside ') and " \
      "contains(concat(' ', normalize-space(@class), ' '), ' note ')]"
  )

  unless notes.length == inventory.length
    raise "Note count mismatch for #{document.fetch("sourceFile")}: " \
      "manifest=#{inventory.length} epub=#{notes.length}"
  end

  inventory.zip(notes).each_with_index do |(admonition, note), index|
    source_reference = admonition.fetch("sourceReference")
    heading_matches = headings_by_reference.fetch(source_reference)
    lesson_ids = heading_matches.flat_map do |heading|
      heading.fetch("lesson_ids").to_s.split("|")
    end.reject(&:empty?)
    lesson_ids = (lesson_ids + parent_heading_reuse.fetch(source_reference, [])).uniq.sort

    unknown_lesson_ids = lesson_ids - catalog_lesson_ids
    unless unknown_lesson_ids.empty?
      raise "Unknown lesson IDs for #{source_reference}: #{unknown_lesson_ids.join(", ")}"
    end

    candidate_id = new_lesson_candidates[source_reference]
    if lesson_ids.empty? && candidate_id.nil?
      raise "Note has no lesson decision: #{source_reference}"
    end

    normalized_text = REXML::XPath.match(note, ".//text()")
      .map(&:value)
      .join(" ")
      .gsub(/\s+/, " ")
      .strip

    rows << {
      "admonition_id" => "#{document.fetch("sourceFile")}#note-#{format("%03d", index + 1)}",
      "admonition_sha256" => Digest::SHA256.hexdigest(normalized_text),
      "source_file" => document.fetch("sourceFile"),
      "source_reference" => source_reference,
      "type" => admonition.fetch("types").join("|"),
      "lesson_ids" => lesson_ids.join("|"),
      "candidate_lesson_id" => candidate_id,
      "coverage_decision" => candidate_id.nil? ? "mapped-to-canonical-lessons" : "requires-new-canonical-lesson",
      "editorial_status" => "pending-editorial-validation",
      "technical_status" => "pending-technical-validation",
      "preview" => normalized_text[0, 240]
    }
  end
end

output_path = File.join(catalog_root, "admonition-coverage.csv")
CSV.open(output_path, "w", write_headers: true, headers: rows.first.keys) do |csv|
  rows.each { |row| csv << row }
end

puts "notes=#{rows.length} mapped=#{rows.count { |row| row.fetch("candidate_lesson_id").nil? }} new_lesson_candidates=#{rows.count { |row| !row.fetch("candidate_lesson_id").nil? }}"
