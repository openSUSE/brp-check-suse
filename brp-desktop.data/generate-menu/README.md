# Menu file generation templates

This is a bunch of data files and templates designed to generate .menu files.

In current form, templates are designed in a way that doesn't make menus look pretty, but instead focuses on providing full list of available categories, used as check .desktop files in OBS.

## Structure

`applications.menu` file in current directory is a template for generated applications.menu
`_data/categories` is a data file specifying what categories get included in applications.menu

# Build

To build the file, you should be able to use any tool that can use liquid templating.

However in development, jekyll was used. Here is how to build the .menu file using jekyll:

```
bundler exec jekyll build
```

Finished file will appear in `_site` directory.
