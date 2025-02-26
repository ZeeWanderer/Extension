//
//  Macros.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

/// A macro that generates encapsulated flat version of the enum by excluding associated values
/// and provides mapping from original to flat enum for case identification purposes.
@attached(member, names: arbitrary)
public macro FlatEnum() =
  #externalMacro(
    module: "Macros", type: "FlatEnumMacro"
  )

@attached(extension, names: arbitrary)
public macro CustomStringConvertibleEnum() =
  #externalMacro(
    module: "Macros", type: "CustomStringConvertibleEnumMacro"
  )
