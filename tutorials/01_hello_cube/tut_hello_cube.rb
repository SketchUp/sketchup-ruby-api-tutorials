# Copyright 2016 Trimble Inc
# Licensed under the MIT license

# This demonstrate the required pattern for Extensions to be accepted to the
# Extension Warehouse.
#
# Key requirements:
#
# * Register a SketchupExtension instance in the root .rb file.
#
# * Do not load anything else in the root .rb file - it should _only_ do
#   registration.
#
# * Confine all code for the extension into its own namespace (module).
#   This means that one should never use global variables, global constants
#   or global methods. It also means that you should not modify the Ruby API or
#   SketchUp API.

# These are needed because we use some methods defined in these files which are
# not automatically loaded by SketchUp.
#
# * sketchup.rb is needed for `file_loaded?` and `file_loaded`.
#
# * extensions.rb is needed for the `SketchupExtension` class.
require 'sketchup.rb'
require 'extensions.rb'

# In order to make sure your extension doesn't affect other installed extensions
# you need to put all your extension code within your own module.
#
# We recommend a pattern similar to this for best flexibility:
#
#   module PublisherName
#     module ExtensionName
#       # ...
#     end
#   end
#
# This allows you to put all your extensions into a single module representing
# you as developer/company.
module Examples
  module HelloCube

    # The use of `file_loaded?` here is to prevent the extension from being
    # registered multiple times. This can happen for a number of reasons when
    # the file is reloaded - either when debugging during development or
    # extension updates etc.
    #
    # The `__FILE__` constant is a "magic" Ruby constant that returns a string
    # with the path to the current file. You don't have to use this constant
    # with `file_loaded?` - you can use any unique string to represent this
    # file. But `__FILE__` is very convenient for this.
    unless file_loaded?(__FILE__)

      # Here we define the extension. The two arguments is the extension name
      # and the file that should be loaded when the extension is enabled.
      #
      # Note that the file loaded (tut_hello_cube/main) must be in a folder
      # named with the same base name as this root file.
      #
      # Another thing to notice is that we omitted the .rb file extension and
      # wrote `tut_hello_world/main` instead of `tut_hello_world/main.rb`.
      # SketchUp is smart enough to find the file regardless and this is
      # required if you decide to later encrypt the extension.
      ex = SketchupExtension.new('Hello Cube', 'tut_hello_cube/main')

      # Next we add some information to the extension. This isn't required, but
      # highly recommended as it helps the user when managing her installed
      # extensions.
      ex.description = 'SketchUp Ruby API example creating a cube.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Navigations © 2016'
      ex.creator     = 'SketchUp'

      # Finally we tell SketchUp to register this extension. Remember to always
      # set the second argument to true - this tells SketchUp to load the
      # extension by default. Otherwise the user has to manually enable the
      # extension after installation.
      Sketchup.register_extension(ex, true)

      # This is needed for the load guard to prevent the extension being
      # registered multiple times.
      file_loaded(__FILE__)
    end

  end # module HelloCube
end # module Examples
