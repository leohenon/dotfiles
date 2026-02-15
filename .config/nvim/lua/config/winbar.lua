local M = {}

function M.navic()
  local ok, navic = pcall(require, "nvim-navic")
  if not ok then
    return ""
  end
  if navic.is_available() then
    return navic.get_location()
  end
  return ""
end

return M
