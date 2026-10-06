@ECHO off

REM TODO: Clean this up!

SET SDKDir="D:\WinAppSDK"
SET PackagesDir="D:\Packages"

@ECHO on
D:\swift-winrt\out\release\bin\swiftwinrt.exe ^
-input "%SDKDir%\Microsoft.WindowsAppSDK.InteractiveExperiences.2.0.15\metadata\10.0.18362.0\Microsoft.UI.winmd" ^
-input "%SDKDir%\Microsoft.WindowsAppSDK.WinUI.2.2.1\metadata\Microsoft.UI.Xaml.winmd" ^
-input "%SDKDir%\Microsoft.WindowsAppSDK.Foundation.2.1.0\metadata\Microsoft.Windows.Foundation.winmd" ^
-input "%SDKDir%\Microsoft.WindowsAppSDK.InteractiveExperiences.2.0.15\metadata\10.0.18362.0\Microsoft.Graphics.winmd" ^
-input "%SDKDir%\Microsoft.WindowsAppSDK.Foundation.2.1.0\metadata\Microsoft.Windows.ApplicationModel.Resources.winmd" ^
-input "%SDKDir%\Microsoft.WindowsAppSDK.WinUI.2.2.1\metadata\Microsoft.UI.Text.winmd" ^
-input "%SDKDir%\Microsoft.Web.WebView2.1.0.3719.77\lib\Microsoft.Web.WebView2.Core.winmd" ^
-input "%PackagesDir%\Microsoft.Graphics.Win2D.1.4.0\lib\uap10.0\Microsoft.Graphics.Canvas.winmd" ^
-input "C:\PROGRA~2\Windows Kits\10\UnionMetadata\10.0.28000.0\Windows.winmd" ^
-include "Microsoft.Graphics.Canvas" ^
-include "Microsoft.Graphics.Canvas.UI.Composition" ^
-include "Microsoft.UI.Colors" ^
-include "Microsoft.UI.Dispatching" ^
-include "Microsoft.UI.Input.InputKeyboardSource" ^
-include "Microsoft.UI.Input.InputNonClientPointerSource" ^
-include "Microsoft.UI.Input.InputSystemCursor" ^
-include "Microsoft.UI.Input.InputSystemCursorShape" ^
-exclude "Microsoft.UI.Xaml.Data.Binding" ^
-exclude "Microsoft.UI.Xaml.Data.BindingBase" ^
-exclude "Microsoft.UI.Xaml.Data.BindingBaseMaker" ^
-exclude "Microsoft.UI.Xaml.Data.BindingExpression" ^
-exclude "Microsoft.UI.Xaml.Data.BindingExpressionBase" ^
-exclude "Microsoft.UI.Xaml.Data.BindingExpressionBaseMaker" ^
-include "Microsoft.UI.Xaml.Window" ^
-include "Microsoft.UI.Xaml.Application" ^
-include "Microsoft.UI.Xaml.Controls.Border" ^
-include "Microsoft.UI.Xaml.Controls.Canvas" ^
-include "Microsoft.UI.Xaml.Controls.Flyout" ^
-include "Microsoft.UI.Xaml.Controls.FlyoutPresenter" ^
-include "Microsoft.UI.Xaml.Controls.Grid" ^
-include "Microsoft.UI.Xaml.Controls.SystemBackdropElement" ^
-include "Microsoft.UI.Xaml.Controls.TextBlock" ^
-include "Microsoft.UI.Xaml.Controls.TextBox" ^
-include "Microsoft.UI.Xaml.Controls.UserControl" ^
-include "Microsoft.UI.Xaml.Controls.WebView2" ^
-include "Microsoft.UI.Xaml.Controls.XamlControlsResources" ^
-exclude "Microsoft.UI.Xaml.Automation" ^
-exclude "Microsoft.UI.Xaml.Automation.Peers" ^
-exclude "Microsoft.UI.Xaml.Automation.Provider" ^
-exclude "Microsoft.UI.Xaml.Documents.Block" ^
-include "Microsoft.UI.Xaml.Hosting" ^
-include "Microsoft.UI.Xaml.Markup.IXamlMetadataProvider" ^
-exclude "Microsoft.UI.Xaml.Markup.IXamlMember" ^
-include "Microsoft.UI.Xaml.Markup.XamlReader" ^
-exclude "Microsoft.UI.Xaml.Media.Animation" ^
-include "Microsoft.UI.Xaml.Media.CompositionTarget" ^
-include "Microsoft.UI.Xaml.Media.DesktopAcrylicBackdrop" ^
-exclude "Microsoft.UI.Xaml.Media.Imaging" ^
-include "Microsoft.UI.Xaml.Media.MicaBackdrop" ^
-exclude "Microsoft.UI.Xaml.Media.Media3D" ^
-include "Microsoft.UI.Xaml.Media.ThemeShadow" ^
-include "Microsoft.UI.Xaml.Media.VisualTreeHelper" ^
-exclude "Microsoft.UI.Xaml.Navigation.FrameNavigationOptions" ^
-include "Microsoft.UI.Xaml.Setter" ^
-include "Microsoft.UI.Xaml.Shapes.Rectangle" ^
-include "Microsoft.UI.Xaml.XamlTypeInfo.XamlControlsXamlMetaDataProvider" ^
-include "Windows.ApplicationModel.DataTransfer.DragDrop.Core" ^
-exclude "Windows.ApplicationModel.DataTransfer.DragDrop" ^
-exclude "Windows.ApplicationModel.Activation" ^
-exclude "Windows.Devices.Input" ^
-include "Windows.Foundation" ^
-exclude "Windows.Foundation.PropertyValue" ^
-include "Windows.Graphics.Imaging" ^
-exclude "Windows.Networking" ^
-exclude "Windows.Networking.Connectivity" ^
-include "Windows.Security.Cryptography.Certificates.Certificate" ^
-include "Windows.Storage.Streams.Buffer" ^
-include "Windows.Storage.Streams.DataReader" ^
-include "Windows.Storage.Streams.InMemoryRandomAccessStream" ^
-exclude "Windows.UI.Notifications" ^
-exclude "Windows.UI.ViewManagement" ^
-include "Windows.UI.Color" ^
-include "Windows.Web.Http" ^
-output .
