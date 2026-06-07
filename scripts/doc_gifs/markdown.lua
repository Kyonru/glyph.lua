local Markdown = {}

local function featureStart(id)
  return "<!-- glyph:feature-gif " .. id .. " -->"
end

local function featureFinish(id)
  return "<!-- /glyph:feature-gif " .. id .. " -->"
end

local galleryStart = "<!-- glyph:feature-gif-gallery -->"
local galleryFinish = "<!-- /glyph:feature-gif-gallery -->"

local function countPlain(content, needle)
  local count = 0
  local from = 1

  while true do
    local index = content:find(needle, from, true)
    if not index then
      break
    end
    count = count + 1
    from = index + #needle
  end

  return count
end

local function replaceBlock(content, startMarker, finishMarker, block)
  local starts = countPlain(content, startMarker)
  local finishes = countPlain(content, finishMarker)

  if starts > 1 or finishes > 1 then
    error("duplicate managed Markdown block: " .. startMarker, 2)
  end

  if starts == 0 and finishes == 0 then
    return nil
  end

  if starts ~= 1 or finishes ~= 1 then
    error("unterminated managed Markdown block: " .. startMarker, 2)
  end

  local startIndex = content:find(startMarker, 1, true)
  local finishIndex = content:find(finishMarker, startIndex + #startMarker, true)
  if not finishIndex then
    error("unterminated managed Markdown block: " .. startMarker, 2)
  end

  return content:sub(1, startIndex - 1) .. block .. content:sub(finishIndex + #finishMarker)
end

local function insertAfterH1(content, block)
  local startIndex, endIndex = content:find("^# [^\n]*\n")
  if not startIndex then
    startIndex, endIndex = content:find("\n# [^\n]*\n")
  end

  if not endIndex then
    error("could not find a top-level heading for managed GIF block", 2)
  end

  local prefix = content:sub(1, endIndex)
  local suffix = content:sub(endIndex + 1)
  if suffix:sub(1, 1) == "\n" then
    suffix = suffix:sub(2)
  end

  return prefix .. "\n" .. block .. "\n\n" .. suffix
end

local function insertBeforeHeading(content, heading, block)
  local marker = "\n" .. heading
  local index = content:find(marker, 1, true)
  if not index then
    return insertAfterH1(content, block)
  end

  local prefix = content:sub(1, index - 1)
  local suffix = content:sub(index + 1)
  return prefix .. "\n\n" .. block .. "\n\n" .. suffix
end

local function pathDepthFromDocs(docPath)
  local relative = tostring(docPath):gsub("^docs/", "")
  local depth = 0

  for _ in relative:gmatch("/") do
    depth = depth + 1
  end

  return depth
end

local function basename(path)
  return tostring(path):match("([^/]+)$") or tostring(path)
end

function Markdown.assetPath(docPath, id)
  return string.rep("../", pathDepthFromDocs(docPath)) .. "assets/feature-gifs/" .. id .. ".gif"
end

function Markdown.docLinkPath(sourceDocPath, targetDocPath)
  local depth = pathDepthFromDocs(sourceDocPath)
  if depth == 0 then
    return basename(targetDocPath)
  end
  return string.rep("../", depth) .. tostring(targetDocPath):gsub("^docs/", "")
end

function Markdown.featureBlock(target, docPath)
  return table.concat({
    featureStart(target.id),
    "![" .. target.alt .. "](" .. Markdown.assetPath(docPath, target.id) .. ")",
    featureFinish(target.id),
  }, "\n")
end

function Markdown.updateFeatureDoc(content, target, docPath)
  local block = Markdown.featureBlock(target, docPath)
  local replaced = replaceBlock(content, featureStart(target.id), featureFinish(target.id), block)

  if replaced then
    return replaced
  end

  return insertAfterH1(content, block)
end

function Markdown.galleryBlock(targets, docPath)
  local lines = {
    galleryStart,
    "## Feature GIF Gallery",
    "",
    "| Feature | Preview |",
    "| --- | --- |",
  }

  for _, target in ipairs(targets) do
    local link = Markdown.docLinkPath(docPath, target.docs[1])
    local asset = Markdown.assetPath(docPath, target.id)
    lines[#lines + 1] = "| [" .. target.title .. "](" .. link .. ") | ![" .. target.alt .. "](" .. asset .. ") |"
  end

  lines[#lines + 1] = galleryFinish
  return table.concat(lines, "\n")
end

function Markdown.updateGalleryDoc(content, targets, docPath)
  local block = Markdown.galleryBlock(targets, docPath)
  local replaced = replaceBlock(content, galleryStart, galleryFinish, block)

  if replaced then
    return replaced
  end

  return insertBeforeHeading(content, "## Example Standards", block)
end

function Markdown.validateTargets(targets)
  local seen = {}

  for index, target in ipairs(targets or {}) do
    if type(target) ~= "table" then
      error("doc GIF target " .. index .. " must be a table", 2)
    end
    if type(target.id) ~= "string" or target.id == "" then
      error("doc GIF target " .. index .. " is missing an id", 2)
    end
    if seen[target.id] then
      error("duplicate doc GIF target id: " .. target.id, 2)
    end
    seen[target.id] = true
    if type(target.title) ~= "string" or target.title == "" then
      error("doc GIF target " .. target.id .. " is missing a title", 2)
    end
    if type(target.alt) ~= "string" or target.alt == "" then
      error("doc GIF target " .. target.id .. " is missing alt text", 2)
    end
    if type(target.docs) ~= "table" or #target.docs == 0 then
      error("doc GIF target " .. target.id .. " must list at least one doc", 2)
    end
  end

  return true
end

return Markdown
