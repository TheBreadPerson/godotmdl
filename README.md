<p align="center">
  <img src="https://raw.githubusercontent.com/TheBreadPerson/godotmdl/refs/heads/main/mdllogo.svg" width="480" alt="MDL Logo">
</p>

<p align="center">

<a href="https://godotengine.org/asset-library/asset/5263" target="_blank">
<img src="https://img.shields.io/badge/asset_library-%23EEEEEE.svg?style=for-the-badge&logo=godot-engine" alt="Godot Asset Library"></a>

<a href="https://store.godotengine.org/asset/elliptical/rumblepak/" target="_blank">
<img src="https://img.shields.io/badge/asset_store-%23333333.svg?style=for-the-badge&logo=godot-engine&logoColor=%23ffffff" alt="Godot Asset Store"></a>
</p>

## About

I couldn't find any good tools to streamline the lengthy process of creating .mdl files, and I plan on using a lot of them in my game. So I made this tool in Godot.

### Features

- Right click conversion to .mdl
- Automatically converts model file to a .smd
- Creates a .qc file
- Converts them into a .mdl

<table>
  <tr>
    <td width="480">
      <img src="https://github.com/TheBreadPerson/godotmdl/blob/main/godot_screenshot.png" alt="Logo" width="480">
    </td>
    <td>
      <h3>Create .mdl file</h3>
      <p>
        With GodotMDL, you can skip the long process required to convert a model into an mdl file.
      </p>
      <p>
         Simply right click your model and click 'Create .mdl file'
      </p>
    </td>
  </tr>
</table>

## How to use
Download this [blank mod folder](https://drive.google.com/drive/folders/1Vitm-praILoZvS5oDnv6yxtsW7pLSBtq) and drag it into your project. (This is for the gameinfo.txt for studiomdl)

After adding GodotMDL into your addons folder, go to Project Settings -> GodotMDL. Configure your studiomdl.exe path (often in the bin folder of source games)

Then, right click your model and click Create .mdl file.

I highly advise you use the [GodotVMF](https://github.com/H2xDev/GodotVMF) plugin which adds support with the Hammer editor, it gives you the ability to view the .mdl file in godot. Otherwise it won't be visible in your file system.

## Installation
1. Click on the green "Code" button and select "Download ZIP".
2. Extract the `addons` folder into the root of your Godot project.
3. Enable the plugin in your Godot project settings.

Tested with Godot 4.6
