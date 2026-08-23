#!/usr/bin/env ruby

require "csv"
require "json"
require "set"

project_root = File.expand_path("..", __dir__)
catalog_root = File.join(project_root, "Content/SourceCatalog/swift-6.4-beta")
manifest_path = File.join(catalog_root, "source-manifest.json")
heading_coverage_path = File.join(catalog_root, "coverage-matrix.csv")
output_path = File.join(catalog_root, "example-coverage.csv")

manifest = JSON.parse(File.read(manifest_path))
heading_rows = CSV.read(heading_coverage_path, headers: true)
headings_by_reference = heading_rows.group_by { |row| row.fetch("source_reference") }

parent_heading_reuse = {
  "GuidedTour/GuidedTour.xhtml#a-swift-tour" => [
    "swift.output.string-interpolation"
  ],
  "LanguageGuide/StringsAndCharacters.xhtml#Unicode-Representations-of-Strings" => [
    "swift.unicode.utf8-view",
    "swift.unicode.utf16-view",
    "swift.unicode.scalar-view"
  ],
  "LanguageGuide/Functions.xhtml#Function-Argument-Labels-and-Parameter-Names" => [
    "swift.functions.argument-label"
  ],
  "LanguageGuide/Concurrency.xhtml#concurrency" => [
    "swift.concurrency.async-function"
  ]
}.freeze

occurrences = manifest.fetch("documents").flat_map do |document|
  document.fetch("examples").map do |example|
    {
      "category" => document.fetch("category"),
      "source_file" => document.fetch("sourceFile"),
      "source_reference" => example.fetch("sourceReference"),
      "sha256" => example.fetch("sha256"),
      "preview" => example.fetch("preview")
    }
  end
end

records = occurrences.group_by { |occurrence| occurrence.fetch("sha256") }.map do |sha256, matches|
  source_references = matches.map { |match| match.fetch("source_reference") }.uniq.sort
  missing_references = source_references.reject { |reference| headings_by_reference.key?(reference) }
  unless missing_references.empty?
    raise "Examples reference unknown headings: #{missing_references.join(", ")}"
  end

  lesson_ids = source_references.flat_map do |reference|
    mapped_ids = headings_by_reference.fetch(reference).flat_map do |heading|
      heading.fetch("lesson_ids").to_s.split("|")
    end.reject(&:empty?)
    mapped_ids + parent_heading_reuse.fetch(reference, [])
  end.uniq.sort

  is_context = lesson_ids.empty?
  unless !is_context || matches.all? { |match| match.fetch("category") == "publication-metadata" }
    raise "Learning example has no canonical lesson mapping: #{sha256}"
  end

  {
    "example_sha256" => sha256,
    "source_files" => matches.map { |match| match.fetch("source_file") }.uniq.sort.join("|"),
    "source_references" => source_references.join("|"),
    "occurrence_count" => matches.length,
    "lesson_ids" => lesson_ids.join("|"),
    "coverage_decision" => is_context ? "reviewed-no-lesson" : "mapped-to-canonical-lessons",
    "editorial_status" => is_context ? "not-applicable" : "pending-editorial-validation",
    "compiler_status" => is_context ? "not-applicable" : "pending-swift-6.4-toolchain",
    "preview" => matches.first.fetch("preview")
  }
end.sort_by { |record| [record.fetch("source_references"), record.fetch("example_sha256")] }

CSV.open(output_path, "w", write_headers: true, headers: records.first.keys) do |csv|
  records.each { |record| csv << record }
end

puts "examples=#{records.length} mapped=#{records.count { |record| !record.fetch("lesson_ids").empty? }} context=#{records.count { |record| record.fetch("lesson_ids").empty? }} occurrences=#{occurrences.length}"
