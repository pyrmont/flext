# Writing Processors

You can write your own processors for Flext using JavaScript. Indeed, this is
how Flext's own processors are implemented.

## Requirements

There are three requirements for a valid processor:

1. **`process()` function**. A Flext processor needs to define a `process()`
   function. While there are multiple ways to define a function in JavaScript,
   the function should be written in the following manner to work properly in
   Flext:

   ```js
   var process = function(text) {
     ...
   }
   ```

   **_Your function **must** be defined using the above style if you want to
   specify additional arguments. If you don't, Flext will not detect that your
   processor has user-definable options._**

2. **Minimum arity of one.** Your function needs to take at least one argument.
   That argument will be the text to be processed and is guaranteed to be a
   non-empty string.

3. **String return value.** Your function will need to return a string. This is
   the processed text.

## Arguments

Your function can include additional arguments. Flext will detect additional
arguments in your function definition and expose an options screen that is
accessible from Flext's Settings screen.

On the options screen, each argument will be listed with a user-editable text
field. The argument's name will be used for the name of the option and, if you
have set a default value, this will appear as the placeholder text. Note that
the values specified here are the values as they will be passed to your
function. To specify a string, for example, enclose the value in `"`.

You can also provide a comment following the argument that will be listed as
explanatory text below the option.

You can see how this is achieved in the built-in **Wrap Markdown** processor:

```js
var process = function(text, wrap_limit = 72 /* The maximum number of characters to display before wrapping */) {
  ...
}
```

For the best experience, additional arguments should have default values so that
your processor will work even if no options have been specified by the user.

## Example

An example of the **Add claps** processor is below:

```js
var process = function(text) {
  const clap = "\uD83D\uDC4F"
  let result = ""

  for (const char of text) {
    result = result + char + (char == " " ? clap + char : "")
  }

  return result
}
```

You can see all the built-in processors in Flext's
[open source repository](https://github.com/pyrmont/flext/).
