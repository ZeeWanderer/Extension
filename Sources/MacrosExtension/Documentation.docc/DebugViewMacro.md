# Debugging View Type Checking

Temporarily expose useful diagnostics when a SwiftUI expression exhausts the
compiler's type-checking budget.

## Apply, diagnose, remove

Import `MacrosExtension` (or the umbrella `Extension` module) and annotate the
problematic body:

```swift
@debug_view
var body: some View {
    VStack {
        Text(.welcomeTitle)
            .font(.headline)
            .padding()
    }
}
```

The macro splits modifier chains into local bindings. Constructor and modifier
arguments remain in their calls; concrete intermediate types such as `Text`
are preserved. A builder body is placed inside a generated local `@ViewBuilder`
function, giving it a separate type-checking scope without adding an `AnyView`,
layout container, task, or escaping closure.

Invalid code must still fail. The intended improvement is a precise error such
as a missing member instead of “unable to type-check this expression.” Once the
error is fixed, **remove `@debug_view` and compile the original code again**.

## Existing builders and ordinary helpers

Both attribute orders work, and the original `@ViewBuilder` stays in the source:

```swift
@ViewBuilder
@debug_view
func content() -> some View {
    Text("First").bold().padding()
    Text("Second").italic().padding()
}
```

`View.body` does not need an explicit builder annotation. Ordinary
single-expression view-returning functions and shorthand computed properties
also work without one, including helpers returning a concrete `Text`.
The macro restores an explicit return when adding bindings would otherwise
remove an ordinary function's implicit return. Async and throwing builder
helpers retain their effects and actor context.

Swift 6.4 has a compiler issue with locals introduced directly into a
body-macro/result-builder combination. The generated helper avoids that issue.
For an explicitly annotated builder, Swift may also warn that an explicit return
bypasses the **outer** builder transform. The helper still performs that
transform; do not remove your original `@ViewBuilder` to silence this warning.

## Debug-only, including when the annotation is forgotten

Use Swift 6.4 / Xcode 27 or newer for the rewrite. The macro checks the
**consuming target's `DEBUG` compilation condition**, not the plugin's build
configuration or optimization level. Standard Debug configurations define it;
custom configurations must set it explicitly.

When `DEBUG` is absent, the macro emits no replacement body: the compiler keeps
the original source. If a compiler
cannot report its build configuration, the macro also leaves the original body
unchanged and explains why. A reminder warning is emitted at every application,
including non-Debug builds. Do not define `DEBUG` in a shipping configuration.

## Conservative boundaries

The macro descends into common SwiftUI builders: stacks, groups, grids, lists,
forms, sections, scroll and geometry readers, `ForEach`, navigation containers,
and recognized content/label closures for controls and presentation modifiers.
Builder `if`, `switch`, availability checks, and conditional compilation retain
their structure. Closure parameters, local bindings, captures and action
closures stay in their original scope.

Button actions, `.task`, `.onAppear`, `.onChange`, and arbitrary custom closures
are not rewritten. Ambiguous `Slider` trailing closures are also left alone,
since they may be editing callbacks. Unknown custom builders are left alone; annotate their
view-producing helper instead. Optional chains, `try`/`await` chains, and
leading-dot receivers that need contextual types are not split. A single large
argument expression may therefore still exceed the compiler's budget.
Rethrowing builder helpers stay unchanged, with an explanatory warning: moving
their captured throwing parameters into a local helper would change the effect
contract. Builder recognition is syntax-based; custom APIs with the same names
as recognized SwiftUI builders may also be rewritten.

This is not a general source-equivalence guarantee or a production optimizer.
Separating expressions can change overload inference and temporary lifetimes.
Check that a new diagnostic refers to the original mistake, then verify the
corrected code without the macro. Diagnostics may point inside the expanded
macro, with a note linking back to its source application.
