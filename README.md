# JetBrowser (Flutter)
A desktop app for browsing parish book scans distributed in ZIP files.

## Building (Windows)
1. Install required tools per [https://flutter.dev/desktop](), namely Flutter SDK and Visual Studio 2019 with the "Desktop development with C++" workload
2. In console change the current directory to the project folder 
3. Call `flutter build windows`

## Running
The example of scanned parish book: [150-02792.zip](http://88.146.158.154:8083/150-02792.zip) (110 MB)

### From console
- Type `jetbrowser.exe 150-02792.zip`

### From File Explorer
- Add a new `Open with JetBrowser` context menu item for any ZIP file by altering Windows registry:
    1. Open `regedit.exe`
    2. In the `HKEY_CLASSES_ROOT\CompressedFolder\Shell` path create a new `JetBrowser` key
    3. Select the `(Default)` key and set `Open with JetBrowser` as a value
    4. Optionally add a new `Icon` key and specify the path as a value
    5. Add a new `command` subkey and specify the JetBrowser executable path followed by `"%1"` as a value,
       for example `C:\jet-browser-flutter\build\windows\runner\Release\jetbrowser.exe "%1"`
- in the File Explorer right click the zip file and choose the `Open with JetBrowser` menu item

## Usage
- Use `<-`/`->` arrows keys to move to the previous/next image
- Use `Shift`/`Ctrl` modifiers together with arrow keys to increase the step to 5/20
- Use `Home`/`End` keys to move to the first/last image
- Use `H`/`W` keys to scale the image to fit the height/width of the window
- Use `R` key to reset the size to the original image size
- Use `C` key to copy the current image filename to the clipboard