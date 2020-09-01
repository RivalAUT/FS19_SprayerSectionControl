# FS19_SprayerSectionControl
Section Control for sprayers in FS19

This script is beta. It should not make any problems but there's always the possibility that something could stop working.

## What is section control?
Section control allows you to turn off certain parts (sections) of your sprayer if you don't need the full working width. 
The sections can be controlled manually and automatically.

The script works with fertilizer and herbicide.

## The HUD
The HUD shows all sections of the sprayer. With the ON/OFF button you can switch between manual and automatic mode.
Turning sections on or off is done by clicking on the red/yellow/green spray in the HUD.

### Colors
- RED: Section is turned off.
- YELLOW: Section is turned on, but sprayer is turned off.
- GREEN: Section is turned on and sprayer is on

### Keys
- *LCTRL* + *B* to toggle HUD
- *MIDDLE MOUSE BUTTON* to toggle mouse cursor (only when HUD is visible)

## What do you need?
At first you will need the script. [Download it here.](https://github.com/RivalAUT/FS19_SprayerSectionControl/raw/master/FS19_SprayerSectionControl.zip)

The script alone does not give you any functionality, you need adapted sprayers too. If Giants had made one workArea per section, this would not be necessary.
But as there is only one workArea for the full working width this is not possible.

### How you make sprayers compatible
Converting sprayers to work with section control is not difficult. You need some entries in the XML and one workArea per section in the i3D.

**Warning: The HUD is restricted to 13 sections. If you have a sprayer with every spray nozzle as extra section you need to group the nozzles to bigger sections for a correct HUD display. In automatic mode, they will still be controlled separately.**

#### i3D part
The workAreas need to be set up around each spraying section, with a little overlap to the next section. 
It is also needed to create a testArea which is a little bigger by increasing the length in driving direction for 1m.

Image: *(testArea uses the height node of the workArea in this example.)*
![workArea setup](http://rival.bplaced.net/SSC_workArea2.png)

#### XML part
The XML part is mainly copy-paste. The following lines need to be copied into the sprayer's XML file.
```
<sprayerSectionControl>
  <sections>
    <section workingWidth="3" workAreaId="1" effectNodeId="1" testAreaStartNode="testAreaStart1"  testAreaWidthNode="testAreaWidth1"  testAreaHeightNode="workAreaHeight1" />
    <section workingWidth="3" workAreaId="2" effectNodeId="2" testAreaStartNode="testAreaStart2"  testAreaWidthNode="testAreaWidth2"  testAreaHeightNode="workAreaHeight2" />
    <section workingWidth="2.5" workAreaId="3" effectNodeId="3" testAreaStartNode="testAreaStart3"  testAreaWidthNode="testAreaWidth3"  testAreaHeightNode="workAreaHeight3" />
    <section workingWidth="2.5" workAreaId="4" effectNodeId="4" testAreaStartNode="testAreaStart4"  testAreaWidthNode="testAreaWidth4"  testAreaHeightNode="workAreaHeight4" />
    <section workingWidth="2" workAreaId="5" effectNodeId="5" testAreaStartNode="testAreaStart5"  testAreaWidthNode="testAreaWidth5"  testAreaHeightNode="workAreaHeight5" />
    <section workingWidth="2.5" workAreaId="6" effectNodeId="6" testAreaStartNode="testAreaStart6"  testAreaWidthNode="testAreaWidth6"  testAreaHeightNode="workAreaHeight6" />
    <section workingWidth="2.5" workAreaId="7" effectNodeId="7" testAreaStartNode="testAreaStart7"  testAreaWidthNode="testAreaWidth7"  testAreaHeightNode="workAreaHeight7" />
    <section workingWidth="3" workAreaId="8" effectNodeId="8" testAreaStartNode="testAreaStart8"  testAreaWidthNode="testAreaWidth8"  testAreaHeightNode="workAreaHeight8" />
    <section workingWidth="3" workAreaId="9" effectNodeId="9" testAreaStartNode="testAreaStart9"  testAreaWidthNode="testAreaWidth9"  testAreaHeightNode="workAreaHeight9" />
   </sections>
</sprayerSectionControl>
```
Although the entries should be self-explaining I will explain them for you:
- All sections get linked to their workAreas and effect nodes here.
- workingWidth is the working width of this section. All section working widths combined should be equal to the total working width (24m in this example). This is used for calculating the spray usage.
- workAreaId is the index of the workArea in the `<workAreas>` part. The first workArea has index/id 1.
- effectNodeId is the index of the effect node in the `<sprayer> <effects>` part. Again, the first effectNode has index/id 1. If more than one effectNodes are used for one section, you can add them like this: `effectNodeId="1 2 3 4"`
- testAreaStartNode / testAreaWidthNode / testAreaHeightNode are indices to the i3D node.
- To set up the groups mentioned earlier paste this before `</sprayerSectionControl>`:
```
  <groups>
    <group sectionIds="1 2 3"/>
    <group sectionIds="4 5 6"/>
    <group sectionIds="7 8 9"/>
  </groups>
```
 This will group sections 1, 2 and 3 to the first HUD section, sections 4, 5 and 6 to the second, etc. There can be up to 13 groups.


That's it!

A sample sprayer (Hardi Mega 2200 from the base game) prepared for section control is available [here.](https://github.com/RivalAUT/FS19_SprayerSectionControl/raw/master/FS19_HardiMega2200.zip)
