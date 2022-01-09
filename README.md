# HUB
 HUB - Assignment

Run the command to install
flutter run --no-sound-null-safety

The --no-sound-null-safety option is not documented in the article https://dart.dev/null-safety/unsound-null-safety.

IDE run arguments/configuration
To set this up in your IDE of choice, you can use:

In IntelliJ/Android Studio: "Edit Configurations" (in your run configurations) → "Additional run args".
In Visual Studio Code: search for "Flutter run additional args" in your user settings.
In both cases, add --no-sound-null-safety.

Test configuration
For tests, you will want to do the same thing:

In IntelliJ/Android Studio: "Edit Configurations" (in your run configurations) → "Additional args".
In Visual Studio Code: search for "Flutter test additional args" in your user settings.
In both cases, add --no-sound-null-safety.
