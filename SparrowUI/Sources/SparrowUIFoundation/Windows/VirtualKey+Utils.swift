#if os(Windows)
import UWP

extension VirtualKey: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case .a: "A"
    case .b: "B"
    case .c: "C"
    case .d: "D"
    case .e: "E"
    case .f: "F"
    case .g: "G"
    case .h: "H"
    case .i: "I"
    case .j: "J"
    case .k: "K"
    case .l: "L"
    case .m: "M"
    case .n: "N"
    case .o: "O"
    case .p: "P"
    case .q: "Q"
    case .r: "R"
    case .s: "S"
    case .t: "T"
    case .u: "U"
    case .v: "V"
    case .w: "W"
    case .x: "X"
    case .y: "Y"
    case .z: "Z"

    case .number0: "0"
    case .number1: "1"
    case .number2: "2"
    case .number3: "3"
    case .number4: "4"
    case .number5: "5"
    case .number6: "6"
    case .number7: "7"
    case .number8: "8"
    case .number9: "9"

    case .back: "Backspace"
    case .tab: "Tab"
    case .enter: "Enter"
    case .escape: "Esc"
    case .space: "Space"

    case .pageUp: "Page Up"
    case .pageDown: "Page Down"
    case .end: "End"
    case .home: "Home"
    case .left: "Left"
    case .up: "Up"
    case .right: "Right"
    case .down: "Down"
    case .insert: "Insert"
    case .delete: "Delete"

    case .f1: "F1"
    case .f2: "F2"
    case .f3: "F3"
    case .f4: "F4"
    case .f5: "F5"
    case .f6: "F6"
    case .f7: "F7"
    case .f8: "F8"
    case .f9: "F9"
    case .f10: "F10"
    case .f11: "F11"
    case .f12: "F12"
    case .f13: "F13"
    case .f14: "F14"
    case .f15: "F15"
    case .f16: "F16"
    case .f17: "F17"
    case .f18: "F18"
    case .f19: "F19"
    case .f20: "F20"
    case .f21: "F21"
    case .f22: "F22"
    case .f23: "F23"
    case .f24: "F24"

    case .oem1: ";"
    case .oemPlus: "+"
    case .oemComma: ","
    case .oemMinus: "-"
    case .oemPeriod: "."
    case .oem2: "/"
    case .oem3: "`"
    case .oem4: "["
    case .oem5: "\\"
    case .oem6: "]"
    case .oem7: "'"

    case .none: "None"
    default: "VirtualKey(\(rawValue))"
    }
  }
}

extension VirtualKey {
  public static var oem1: VirtualKey { VirtualKey(rawValue: 0xba) }
  public static var oemPlus: VirtualKey { VirtualKey(rawValue: 0xbb) }
  public static var oemComma: VirtualKey { VirtualKey(rawValue: 0xbc) }
  public static var oemMinus: VirtualKey { VirtualKey(rawValue: 0xbd) }
  public static var oemPeriod: VirtualKey { VirtualKey(rawValue: 0xbe) }
  public static var oem2: VirtualKey { VirtualKey(rawValue: 0xbf) }
  public static var oem3: VirtualKey { VirtualKey(rawValue: 0xc0) }
  public static var oem4: VirtualKey { VirtualKey(rawValue: 0xdb) }
  public static var oem5: VirtualKey { VirtualKey(rawValue: 0xdc) }
  public static var oem6: VirtualKey { VirtualKey(rawValue: 0xdd) }
  public static var oem7: VirtualKey { VirtualKey(rawValue: 0xde) }
}

extension VirtualKey {
  public static func numberKey(for number: Int) -> Self {
    switch number {
    case 0: .number0
    case 1: .number1
    case 2: .number2
    case 3: .number3
    case 4: .number4
    case 5: .number5
    case 6: .number6
    case 7: .number7
    case 8: .number8
    case 9: .number9
    default:
      preconditionFailure("Invalid number!")
    }
  }
}
#endif
