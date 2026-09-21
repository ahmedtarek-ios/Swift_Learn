#!/usr/bin/env ruby

require "csv"
require "digest"
require "json"
require "pathname"

SOURCE_PATH = Pathname(ARGV.fetch(0))
ROOT = Pathname(__dir__).parent
CATALOG_PATH = ROOT / "Swift Learn/Data/Content/git-commands-foundations.json"
SOURCE_CATALOG_PATH = ROOT / "Content/SourceCatalog/git-commands"

CATEGORIES = {
  "Repository Bundles" => ["git.bundles", "Repository Bundles", "Package repositories for transfer without network access."],
  "Maintenance / Repository Health" => ["git.maintenance", "Maintenance / Repository Health", "Inspect, validate, and maintain repository storage."],
  "Patch Commands" => ["git.patches", "Patch Commands", "Create, exchange, and apply patch-based changes."],
  "Notes / Metadata" => ["git.notes", "Notes / Metadata", "Attach and manage metadata on Git objects."],
  "Useful Information Commands" => ["git.information", "Useful Information Commands", "Summarize and verify repository information."],
  "Object / Index Manipulation" => ["git.objects-index", "Object / Index Manipulation", "Work directly with objects, trees, packs, and the index."],
  "Low-Level Inspection" => ["git.inspection", "Low-Level Inspection", "Inspect revisions, refs, trees, packs, and repository internals."],
  "Git Server / Protocol Commands" => ["git.server-protocol", "Git Server / Protocol Commands", "Support Git transport and server-side protocol operations."],
  "Internal Helper Commands" => ["git.helpers", "Internal Helper Commands", "Use Git helpers for attributes, credentials, mail, hooks, and formatting."],
  "External Version-Control Systems" => ["git.external-vcs", "External Version-Control Systems", "Exchange history with other version-control systems and import formats."],
  "Daily Git Workflow" => ["git.daily", "Daily Git Workflow", "Handle common branch, commit, synchronization, and recovery tasks."]
}.freeze

WARNINGS = {
  "historyMutation" => "This command changes commit or reference history. Confirm the target and whether the history has been shared before proceeding.",
  "destructiveCleanup" => "This command can permanently remove repository data. Verify recoverability and the exact target before proceeding.",
  "credentialOrServerOperation" => "This command handles credentials or exposes a Git service. Review access, storage, and network security before use.",
  "experimentalOrSpecialized" => "This is a specialized or low-level command. Review the installed Git version documentation and test in a disposable repository first."
}.freeze

def slug(value)
  value.downcase
       .gsub(/[^a-z0-9]+/, "-")
       .gsub(/\A-|\z-/, "")
end

def title_for(description)
  description
    .sub(/\A(Git )?/, "")
    .split
    .map { |word| %w[a an and as by for from in into of on or over the to with].include?(word.downcase) ? word.downcase : word.capitalize }
    .join(" ")
    .sub(/\A./, &:upcase)
end

def safety_level(command, category)
  return "destructiveCleanup" if command.match?(/\bgit (prune|prune-packed|gc|repack|pack-redundant)\b/) || command.include?("reset --hard")
  return "credentialOrServerOperation" if category == "Git Server / Protocol Commands" || command.match?(/\bgit credential(?:-|\b)/)
  return "experimentalOrSpecialized" if ["Object / Index Manipulation", "Low-Level Inspection", "Internal Helper Commands", "External Version-Control Systems"].include?(category)
  return "historyMutation" if command.match?(/\bgit (commit|rebase|reset|revert|cherry-pick|merge|branch -d|push origin --delete|tag|notes (add|edit|remove)|update-ref|symbolic-ref|am|format-patch)\b/)
  return "workingTreeMutation" if command.match?(/\bgit (add|apply|restore|stash|switch|pull|push|checkout-index|read-tree|update-index)\b/)

  "readOnly"
end

def parse_rows(source)
  rows = [{
    command: "git bundle create repo.bundle --all",
    description: "Create a portable bundle containing every repository reference",
    category: "Repository Bundles",
    line: 1
  }]
  heading = nil

  source.each_line.with_index(1) do |line, line_number|
    heading_match = line.match(/^## \d+\. (.+)$/)
    heading = heading_match[1] if heading_match
    heading = "Daily Git Workflow" if line.start_with?("# ⭐ Commands")
    next unless CATEGORIES.key?(heading)
    next unless line.start_with?("|")

    cells = line.split("|").map(&:strip).reject(&:empty?)
    next if cells.empty? || cells.any? { |cell| cell.match?(/\A-+\z/) }

    if heading == "Daily Git Workflow"
      next if cells[0] == "Task"
      command = cells[1]&.match(/`(git[^`]+)`/)&.captures&.first
      description = cells[0]
    else
      next if cells[0] == "Command"
      command = cells[0]&.match(/`(git[^`]+)`/)&.captures&.first
      description = cells[1]
    end
    next unless command && description

    rows << { command:, description:, category: heading, line: line_number }
  end
  rows
end

source = SOURCE_PATH.read
rows = parse_rows(source)
grouped = rows.group_by { |row| row[:command] }
abort "Expected 139 unique commands, found #{grouped.count}" unless grouped.count == 139

canonical_rows = grouped.values.map(&:first)
lessons_by_category = canonical_rows.group_by { |row| row[:category] }

categories = CATEGORIES.map do |source_title, (category_id, title, summary)|
  category_rows = lessons_by_category.fetch(source_title, [])
  lessons = category_rows.each_with_index.map do |row, index|
    command = row[:command]
    description = row[:description].sub(/[.。]\z/, "")
    lesson_id = "#{category_id}.#{slug(command.sub(/\Agit /, ""))}"
    safety = safety_level(command, source_title)
    distractor_pool = (category_rows.drop(index + 1) + category_rows.take(index)).map { |item| item[:command] }
    distractor_pool += canonical_rows.map { |item| item[:command] } if distractor_pool.length < 2
    choices = ([command] + distractor_pool.reject { |candidate| candidate == command }.first(2)).each_with_index.map do |choice, choice_index|
      { "id" => "#{slug(choice)}-#{choice_index + 1}", "command" => choice }
    end
    correct_choice_id = choices.first.fetch("id")
    references = grouped.fetch(command).map do |appearance|
      "attachment:line-#{appearance[:line]}:#{slug(command)}"
    end

    lesson = {
      "id" => lesson_id,
      "title" => title_for(description),
      "objective" => "Identify the Git command used to #{description.downcase}.",
      "scenario" => "A repository task requires you to #{description.downcase}. Choose the exact command from the attachment that completes this task.",
      "prompt" => "Which Git command should you use?",
      "choices" => choices,
      "correctChoiceID" => correct_choice_id,
      "correctFeedback" => "Correct. #{command} is used to #{description.downcase}.",
      "incorrectFeedback" => "Use #{command} to #{description.downcase}.",
      "sourceReferences" => references,
      "safetyLevel" => safety
    }
    lesson["safetyWarning"] = WARNINGS.fetch(safety) if WARNINGS.key?(safety)
    lesson
  end

  { "id" => category_id, "title" => title, "summary" => summary, "lessons" => lessons }
end

catalog = {
  "schemaVersion" => 1,
  "sourceID" => "git-commands-attachment-v1",
  "editionTitle" => "Git Commands",
  "categories" => categories
}

SOURCE_CATALOG_PATH.mkpath
CATALOG_PATH.write(JSON.pretty_generate(catalog) + "\n")

CSV.open(SOURCE_CATALOG_PATH / "command-inventory.csv", "w") do |csv|
  csv << %w[command lesson_id category_id description first_source_line duplicate_source_lines safety_level]
  categories.each do |category|
    category.fetch("lessons").each do |lesson|
      command = lesson.fetch("choices").find { |choice| choice.fetch("id") == lesson.fetch("correctChoiceID") }.fetch("command")
      source_rows = grouped.fetch(command)
      csv << [command, lesson.fetch("id"), category.fetch("id"), source_rows.first.fetch(:description), source_rows.first.fetch(:line), source_rows.drop(1).map { |item| item.fetch(:line) }.join(";"), lesson.fetch("safetyLevel")]
    end
  end
end

CSV.open(SOURCE_CATALOG_PATH / "coverage-matrix.csv", "w") do |csv|
  csv << %w[lesson_id command practical_scenario choice_count correct_choice_valid source_reference_count safety_warning_valid]
  categories.each do |category|
    category.fetch("lessons").each do |lesson|
      correct = lesson.fetch("choices").find { |choice| choice.fetch("id") == lesson.fetch("correctChoiceID") }
      warning_valid = !WARNINGS.key?(lesson.fetch("safetyLevel")) || !lesson.fetch("safetyWarning", "").empty?
      csv << [lesson.fetch("id"), correct.fetch("command"), !lesson.fetch("scenario").empty?, lesson.fetch("choices").count, !correct.nil?, lesson.fetch("sourceReferences").count, warning_valid]
    end
  end
end

manifest = {
  "schemaVersion" => 1,
  "sourceID" => "git-commands-attachment-v1",
  "sourceFile" => SOURCE_PATH.basename.to_s,
  "sourceSHA256" => Digest::SHA256.hexdigest(source),
  "canonicalCommandCount" => grouped.count,
  "sourceAppearanceCount" => rows.count,
  "duplicateCanonicalCommands" => grouped.count { |_command, appearances| appearances.count > 1 },
  "categoryCount" => categories.count,
  "categories" => categories.map { |category| { "id" => category.fetch("id"), "lessonCount" => category.fetch("lessons").count } },
  "excludedExamples" => ["git format-patch main..feature/login"],
  "excludedProseReferences" => ["git help --all"]
}
(SOURCE_CATALOG_PATH / "source-manifest.json").write(JSON.pretty_generate(manifest) + "\n")

puts "Generated #{grouped.count} lessons across #{categories.count} categories."
