//
//  DebugView.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

/// Temporarily splits view modifier chains into smaller type-checking problems.
///
/// Apply this to `View.body`, another computed getter, or a view-producing
/// function. An explicit `@ViewBuilder` is supported but is not required for
/// `View.body` or an ordinary single-expression view-returning function.
///
/// The consuming target must define `DEBUG`. Other configurations keep the
/// original body, regardless of how the macro plugin itself was built. A host
/// that cannot report its build configuration also keeps the original body.
/// Use Swift 6.4 / Xcode 27 or newer for the diagnostic rewrite.
///
/// Rewrites nested standard SwiftUI builder closures, but not arbitrary custom
/// builders or action closures. Optional chains and context-dependent leading-dot
/// receivers are left intact. This is a diagnostic aid, not a general-purpose
/// optimizer or a guarantee that every type-checking failure can be simplified.
/// Builder bodies use a generated local `@ViewBuilder` function to isolate
/// inference. Swift 6.4 may additionally warn about bypassing the outer builder
/// transform with a return; the helper retains the original builder semantics.
///
/// - Warning: Every use emits a reminder. Remove the annotation after fixing the
///   error and compile the original code again: introducing local bindings can
///   change overload inference and temporary-value lifetimes. See
///   <doc:DebugViewMacro> for supported boundaries and the debugging workflow.
@attached(body)
public macro debug_view() = #externalMacro(module: "Macros", type: "DebugViewMacro")
