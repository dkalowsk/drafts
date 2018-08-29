# Consolidation of Linter Commands

## Abstract 

This paper proposes the addition of the attribute [[tooling]] to add a unified language mechanism for communicating with external C++ tooling.

This paper uses the term `external tooling` to indicate an application that
parses C++ source code to walk an Abstract Syntax Tree (AST) to conduct some
transformation or analysis other than an Immediate Representation.

## Background

A vast industry exists around external tooling within the C++ language, with
many different providers all with the goal of helping to develop error-free
code.  Taking an incomplete tour via an internet search results
in several available static linters.  With choices from free to commercial,
a developer has plenty of choices, including (but not limited to) the following:

- cppcheck (http://cppcheck.sourceforge.net/)
- clang-tidy (http://clang.llvm.org/extra/clang-tidy/)
- clang-format (https://clang.llvm.org/docs/ClangFormat.html)
- Coverity (https://scan.coverity.com/)
- oclint (http://oclint.org/)
- Klockwork (http://www.klocwork.com/products-services/klocwork)
- PVS-Studio (https://www.viva64.com/en/pvs-studio/)

There are even community created documents that consolidate lists of tools with
the goal of helping developers create better code[1].

An external tool provides some level of functionality, with developers needing to
consider tradeoffs of complexity, coverage, and analysis speed.  There exists in
every external tooling, a custom inline mechanism(s) to disable or supress the
flagging of items of interest or false positives. 

In the most simple example, clang-tidy uses a `// NOLINT` to disable all 
possible processing on a line.

These inline communication mechanisms can become much more detailed, providing
details towards specific features, functions, or checks to disable. For example,
within Coverity it is possible to disable the variable dereferencing
operation with `// coverity[var_deref_op]` while PVS-Studio uses `//-V522`.

Many software projects will employ multiple versions of these tools, creating a
precarious situation when updating tools, searching for disabled/supressed lines,
and even trying to add an external tooling control block.


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
    [[tooling::$tool::$action("$content")]]
    ```


### Tooling attribute

The value of `$tool` represents the name of a specific external tool that the
attribute is directing an action towards.  For example, `$tool` can be
`cppcheck` or `coverity`, which means any commands afterwards are directed
towards the stated application.

Alternatively, a `$tool` value of `*` would indicate the following command
applies to all external tools examining the specific line of code.

The value of `$action` represents the specific behavior to take by the
external tool.

1. The attribute can be used to alter external tool functionality for
    sections of code when used on a standalone line and defined as the
     `$action`.  Proposed options for `action` are:
    1. `enable` - Informs external tooling to start any and all processing from
       this point forward.  Example: `[[tooling::clang_format::enable]]`
    1. `disable` - Informs external tooling to stop any and all processing from
       this point forward.  Example: `[[tooling::pvs_studio::disable]]`
1. The attribute can be used to mark various names, entities, and
        expression statements that cause an external tool to flag a line.
        Proposed options for `action` line flagging are:
    1. `suppress` - Informs external tooling to disable a specific action(s) on
       the line, based upon a code provided by the external tooling vendor.
       Example: `[[tooling::clang-tidy::suppress("google-explicit-constructor")]]`
1. (UNSURE) The attribute may be applied to the declaration of a class, a
        typedef­name, a variable, a non­static data member, a function, an
        enumeration, a template specialization, or a non­-null expression
        statement.
    1. NOTE: While a neat idea to apply external tool control on a per object
       basis rather than per line basis, it's unclear if current tooling
       would allow for that level of control.  Therefore it may be best to
       delay any conversation about such changes until a later date.


### Design Considerations

Currently most external tools use a command mechanism based off of a comment
C or C++ block.  With the introduction of attributes in C++, the time is
correct to introduce a unified way within the language to communicate with
external tooling.

The continued use of a comment block processing format cannot be enforced,
and should be thought of as ignored by any compiler front-end parser.

An argument can be made that external tools work on multiple languages, and
therefore the comment parsing works best.  While maintaining the command in a
comment initially sounds correct and feasible, the complexity of the C++
lanaguage parsing points towards a long-term sustainability as being part of the
language specification.

To work within the current grammar of attributes[2], all external tooling must
recognize their naming with underscores (_) as a subtitution for hyphenation.

# Wording

Modify Attribute syntax and semantics [dcl.attr.grammar] as follows
(underscore means inserted text):

    attribute-namespace:
        identifier
        _attribute-namespace :: opt identifier_

## References

[1] https://github.com/mre/awesome-static-analysis
[2] http://eel.is/c++draft/dcl.attr#:attribute

## Revision History 
