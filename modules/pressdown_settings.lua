--========================================================--
-- YATP Pressdown Settings
-- Key and modifier definitions for the pressdown module
--========================================================--

if not YATP then YATP = {} end
if not YATP.Pressdown then YATP.Pressdown = {} end

YATP.Pressdown.settings = {
  keys = {
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=",
    "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]",
    "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'",
    "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/",
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPAD0",
    "SPACE", "TAB", "ESCAPE", "ENTER", "BACKSPACE",
    "MOUSEWHEELUP", "MOUSEWHEELDOWN",
    "BUTTON3", "BUTTON4", "BUTTON5"
  },
  modifiers = { "ALT", "CTRL", "SHIFT" }
}