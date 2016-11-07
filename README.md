# Getting Started & Tutorials

## Example Extensions

We often find that we need a level of training that goes well beyond the basics,
but is more informative than just reading the API documentation. Look no
further! Check out our Example Extensions section for examples of fully
functioning SketchUp Extensions, complete with comments and helpful hints.

### How Do I Use These Tutorials?

Hopefully you can use these examples however you want. The Example code is
available 3 different ways. You can:

1. Read the [Example Extensions tutorials on the SketchUp Developer website](http://stg.developer.sketchup.com/en/content/tutorials).
   Read through the step by step tutorial of the code and comments and try to
   follow along by building the same extension yourself. Use these examples to
   help learn better SketchUp API usage.
2. Fork the [fully commented examples from Github](https://github.com/SketchUp/sketchup-ruby-api-tutorials/tree/master/tutorials).
   Get the code right on your machine, will all the comments for easy access.
   Use it as a quick reference to comments, code snippets, etc.
3. Fork the [non-commented version from Github](https://github.com/SketchUp/sketchup-ruby-api-tutorials/tree/master/examples).
   This is handy for people who just want to look at the code quickly and move
   on. You can copy and paste chunks of code easily from the non-commented
   samples without the verbose comments getting in the way.

Depending what you are trying to achieve, there is a method to get their easily.
Just get all the code at once, and pull out what you need. Or follow along line
by line, tutorial style. The end goal is for everyone to gain access to solid
code examples that help improve their SketchUp extensions.

## Loading Directly from the Repository

If you clone this repository to your computer you can load the files directly
from where you cloned them using a proxy loading script:

```
# Create a file in your Plugins folder with these lines:
$LOAD_PATH << 'some\path\to\sketchup-ruby-api-tutorials'
require 'load_tutorials.rb'
```

That snippet will take care of loading the examples and tutorials.

If you are working on you own examples you want to contribute back via a Pull
Request you can use `Examples.reload` while you work to reload all the files.
