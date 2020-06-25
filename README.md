# FS19_SprayerSectionControl
Section Control for sprayers in FS19

This script is beta. It should not make any problems but don't hit me if your ingame sprayer or savegame won't work anymore.

## What is section control?
Section control allows you to turn off certain parts (sections) of your sprayer if you don't need the full working width. 
At the moment this is done completely automatic but in future there might be an option to control it manually.

## What do I need?
At first you will need the script. [Download it here.](https://github.com/RivalAUT/FS19_SprayerSectionControl/raw/master/FS19_SprayerSectionControl.zip)

The script alone does not give you any functionality, you need adapted sprayers too. If Giants had made one workArea per section, this would not be necessary.
But as there is only one workArea for the full working width this is not possible.

### How you make sprayers compatible
Converting sprayers to work with section control is not difficult. You need some entries in the XML and one workArea per section in the i3D.

#### i3D part
The workAreas need to be set up around each spraying section, with a little overlap to the next section. 
It is also needed to create a testArea which is a little bigger by increasing the length in driving direction for 1m.

Image: *(testArea uses the height node of the workArea in this example.)*
![workArea setup](http://rival.bplaced.net/SSC_workArea.png)

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
- testAreaStartNode / WidthNode / HeightNode are indices to the corresponding i3D node. This is done via i3DMappings.


That's it! I recommend to set the delay of all effectNodes to 0 for instant turning on/off.

A sample sprayer (Hardi Mega 2200 from the base game) prepared for section control is available [here.](https://github.com/RivalAUT/FS19_SprayerSectionControl/raw/master/FS19_HardiMega2200.zip)
