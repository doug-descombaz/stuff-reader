---
trigger: always_on
---

* Always run tests for code for declaring action complete. Attempt to create a test if there was not.
* Follow clean code architecture. Always describe why the architecture choice is made.
* Always maintain folder README.md files. They should describe the folder, and how the files inside of it relate to other parts of the project and in the clean code architecture.
* Always add entry and exit logs for dart functions.
* Don't mix ui event code in the visual layout of the build() function. Place this code in private functions above the build function. Leave a comment next to the private function that describes the object tree path from which it was invoked (if reasonable to disambiguate, part of the path can also be used in the function name).