# Consolidation of External Tooling Commands

## Abstract 

This paper proposes the addition of the attribute [[tooling]] to add a unified
language mechanism for communicating with external C++ tooling.  This would
serve as a replacement for the current ad-hoc collection of control mechanisms
that form around most code-analysis tools.  By providing a uniform mechanism
for this communication a developer will be able to clearly search for sections
of code currently disabling external tooling, remove any possible confusion
towards the action happening, and finally be assured that the requested action
will be supported across all compilers (even if the external tooling does not
in tools current state).

This paper uses the term `external tooling` to indicate an application that
parses C++ source code to walk an Abstract Syntax Tree (AST) to conduct some
transformation or analysis other than an Immediate Representation (IR).

## Background

A vast industry exists around external tooling within the C++ language, with
many different providers all with the goal of helping to develop error-free
code.  Taking an incomplete tour via an internet search results
in several available.  With choices from free to commercial,
a developer has plenty of choices, including (but not limited to) the
following:

- cppcheck (http://cppcheck.sourceforge.net/)
- clang-tidy (http://clang.llvm.org/extra/clang-tidy/)
- clang-format (https://clang.llvm.org/docs/ClangFormat.html)
- Coverity (https://scan.coverity.com/)
- oclint (http://oclint.org/)
- Klockwork (http://www.klocwork.com/products-services/klocwork)
- PVS-Studio (https://www.viva64.com/en/pvs-studio/)
- Bullseye (https://www.bullseye.com/)

There are even community created documents that consolidate lists of tools with
the goal of helping developers create better code[1].

An external tool provides some level of functionality, with developers needing
to consider trade-offs of complexity, coverage, and analysis speed.  There
exists in every external tooling, a custom inline mechanism(s) to disable or
suppress the flagging of items of interest or false positives.

Many software projects employ multiple versions of these tools, creating a
precarious situation when updating tools, searching for disabled/suppressed
lines, and even trying to add an external tooling control block.

There are currently at least three identified mechanisms for control:
- Structured comments
- Compiler specific attribute markers
- Preprocessor macros

### Structured Comments

Most tools provide some form of a structured comment mechanism to conduct
inline external tooling control.  The comment format is a collection of ad-hoc
tooling dependent notations placed within a comment block for the code.  For
example, clang-tidy uses a `// NOLINT` to disable all possible processing on a
line.

These inline communication mechanisms can become much more complicated,
providing details towards specific features, functions, or checks to disable
with varying levels of clarity.  For example, within Coverity it is possible to
disable the variable dereferencing with `// coverity[var_deref_op]`
while PVS-Studio uses `//-V522`.


### Compiler-specific Attribute Markers

Some tools implement their control mechanisms through compiler specific
extensions.  OCLint uses GCC's `__attribute__` command to suppress
falsely flagged items.  For example, an unused local variable warning is
suppressed with:

  `__attribute__((annotate("oclint:suppress[unused local variable]")))`


### Preprocessor Macros

Another portion of tools implement their own preprocessor macro to communicate
commands and control to their tooling.  For example, to exclude a fragment of
code from analysis in PVS-Studio a developer would do the following:

```cpp
  #if !defined(PVS_STUDIO)

  // Some longer code section here
  // that is to be ignored by external
  // tooling.

  #endif // !defined(PVS_STUDIO)

```

Other tools utilize preprocessor macros a little differently.  For example, to
exclude a line of code from Bullseye, a developer can use the compiler `pragma`
operative like so:

 ```cpp
  #pragma BullseyeCoverage ignore
  if (p != nullptr) {
    // do something interesting
  }
```

The use of the `pragma` operator introduces other challenges.  A compiler
configured to issue warnings on unknown pragmas will now encounter the external
tooling line and throw a warning.  Both GCC and clang include the unknown
pragma warning as part of their `-Wall` configuration, while Visual Studio
includes the unknown pragma warning as part of the level 1 warning series.

 - clang/gcc : ` warning: unknown pragma ignored [-Wunknown-pragmas]`
 - Visual Studio : `warning C4068: unknown pragma`

When a project is configured to build with warnings as errors, this pragma will
now generate a compile error.  This can be solved with the use of another
preprocessor definition to obscure the line from other external tools.  For
example, Bullseye entries can look like:

```cpp
#if _BullseyeCoverage
  #pragma BullseyeCoverage ignore
#endif
  if (p != nullptr) {
    // do something interesting
  }
```


In summary, ensuring that any and all external tooling is setup properly will
always be a practice in massaging the source code.  In cases where code
needs to work with multiple compilers, the process can become an exercise in
code mangling.  All this effort moves a developer from worrying about writing
clear, clean, and concise code into worrying how non-standard undocumented
functionality will interact with the C++ language and each compiler.

## Proposal

As of C++17 there are 6 standard attributes in the C++ language.  They are:
  - [[noreturn]]
  - [[carries_dependency]]
  - [[deprecated]]
  - [[unused]]
  - [[nodiscard]]
  - [[fallthrough]]

This paper proposes the inclusion of a new attribute to unify the communication
to external tooling.  This would not only make it easier to remember, but
simplify the search and maintaince of any communication.

The proposed format is:
    ```
    [[tooling::$tool::$action("$tag")]]
    ```


### Tooling attribute

The value of `$tool` represents the name of a specific external tool that the
attribute is directing an action towards.  For example, `$tool` can be
`cppcheck` or `coverity`, which directs any commands afterwards are to be
parsed and acted upon by that specific tool.

Alternatively, a `$tool` value of `*` would indicate the following command
applies to all external tools examining the specific line of code.

The value of `$action` represents the specific behavior to take by the
external tool.

1. The attribute can be used to alter external tool functionality for
    sections of code when used on a standalone line and defined as the
     `$action`.  Proposed options for `action` are:
    1. `enable` - Informs external tooling to start any and all processing from
       this point forward.

        Example: `[[tooling::clang_format::enable]]`

    1. `disable` - Informs external tooling to stop any and all processing from
       this point forward.

       Example: `[[tooling::pvs_studio::disable]]`

    1. Combining the `$action` `enable` or `disable` functionality with the
       `$tool` value of `*`, creates a mechanism to communicate to all external
       tooling parsing over a section of code.

1. The optional `$action` attribute is used to mark various names, entities,
    and expression statements that cause an external tool to flag a line.
    Proposed options for `action` attribute are:

    1. `suppress` - Informs external tooling to disable a specific action(s) on
       the line, based upon a code provided by the external tooling vendor.

       Example: `[[tooling::clang-tidy::suppress("google-explicit-constructor")]]`

1. The attribute may be applied to the declaration of a class, a
        typedef­name, a variable, a non­static data member, a function, an
        enumeration, a template specialization, or a non­-null expression
        statement.
    1. NOTE: While a neat idea to apply external tool control on a per object
       basis rather than per line basis, it's unclear if current tooling
       would allow for that level of control.  Therefore it may be best to
       delay any conversation about such changes until a later date.


### Design Considerations

This paper is not attempting to define what are and what are not valid control
codes for external tooling.  Instead the focus must be on how the codebase
communicates the already established control codes to external tooling.

To work within the current grammar of attributes[2], all external tooling must
recognize their naming with underscores (_) as a substitution for hyphenation.
For example, `clang-tidy` must be recognized as `clang_tidy`.

Currently a majority of external tools use a command mechanism based off of a
comment C or C++ block.  This was historically the best way to provide a
control mechanism that would not impact any compiler, as a comment was ignored
during the parsing process.  The use of preprocessor macros and compiler
specific attribute extensions, while functional, creates a convoluted series of
logic jumps for any human to follow when multiple tools are utilized 

With the introduction of attributes in C++, there exists for a first time, the
ability to define within the language a mechanism to unify a way to communicate
with external tooling and still provide proper compiler aware behaviors.

There is some precedent for the use of attributes to control external tooling.
The CppCoreGuidelines[3] has already established tools that "implement these
rules shall respect the following syntax to explicitly suppress a rule:
`[[gsl::suppress(tag)]]`"

Even with the explicit ruling there exist some challenges where different
compilers do not completely support the same format, resulting in variations to
accomplish the same behavior with the attribute.  For example:
- MSVC understands `[[gsl::suppress(tag.x)]]`
- clang understands `[[gsl::suppress("tag.x")]]`

This problem[4] is highlighted in the Microsoft GSL's gsl_assert.

An argument can be made that external tools work on multiple languages, and
therefore the comment parsing works best.  While maintaining the command in a
comment initially sounds correct and feasible, recall the complexity of the C++
language requires the ability to correctly parse the syntax already.  Meaning
any and all external tooling already has to be ISO C++ standards compliant.
The addition of an attribute for external tool control will not present a major
difficulty for support, while also providing long-term sustainability as part
of the language specification.


# Wording

Modify Attribute syntax and semantics [dcl.attr.grammar] as follows
(underscore means inserted text):

    attribute-namespace:
        identifier
        _attribute-namespace :: opt identifier_

## References

- [1] A sampling of some sites:
  -  https://github.com/mre/awesome-static-analysis
  -  https://github.com/fffaraz/awesome-cpp#static-code-analysis

- [2] http://eel.is/c++draft/dcl.attr#:attribute
- [3] http://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#inforce-enforcement
- [4] https://github.com/Microsoft/GSL/blob/1995e86d1ad70519465374fb4876c6ef7c9f8c61/include/gsl/gsl_assert#L27

## Revision History 
