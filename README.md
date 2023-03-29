![AgX_vs_Filmic](https://user-images.githubusercontent.com/59176246/228416284-fe8e5a45-2dbb-4edf-bb36-52906c32a813.png)
AgX (Left) vs Filmic (Right)

**What?**


Eary's AgX is an OCIO v2 configuration maded with the intension to replace Blender's default config, to give Blender a better color management and image formation for the upcoming Spectral Cycles.

The config was built more specifically for Blender, but other software that supports OCIO v2 should also be able to use it. 

The two featuring image formations (view transforms) are Guard Rail and AgX. Guard Rail is targeted as a replacement for Blender's "Standard", while AgX is targeted as a replacement for "Filmic".

"AgX" the name is a pseudo-chemical notation of silver halide, commonly used in photographic film, therefore, AgX is an alias of Filmic.

AgX is similar to Filmic as a sigmoid-driven formation, while Guard Rail is a minimalist image formation that broke-out from AgX, that only touchs values outside of the valid [0, 1] target display medium range. 

`AgX` Image formation does two things
- It forms a [0.0, 1.0] closed domain image from the unbounded radiometric-like tristimulus data that modern 3D render engines like Cycles and Eevee produce. 
- It provides smooth chromatic attenation in the image accross challenging use cases including wider gamut rendering, real-camera-produced colorimetry etc.

This config also comes with a different colorspace naming scheme, but with backwards compatibility setup with OCIO v2 feature of aliaes, so that texture colorspaces in old .blend files will get auto-converted to the new names. 

Three of the frequently asked space names are:
- `Generic Data`, this corresponds to the legacy `Non-Color` and `Raw`
- `sRGB 2.2`, this corresponds to the legacy `sRGB`
- `Linear BT.709 I-D65`, this corresponds to the legacy `Linear`

**Why?**

Because the current Filmic has issues like the Notorious Six, meaning Filmic collapes all colors into six before attenuating to white. Filmic also doesn't have the capability to handle wider gamut render produced by wider working space, spectral rendering, real-camera-produced colorimetry etc. 

**How?**

1. Download the latest version of Eary's AgX, Replace your current OpenColorIO configuration in Blender with this version.

2. The Blender OpenColorIO configuration directory is located in:

  BLENDER/bin/VERSIONNUMBER/datafiles/colormanagement
  Move the existing colormanagement directory to a backup location, and place the contents of this repository into a new colormanagement directory.

3. From within the Color Management panel, change the View to AgX, and choose the artistic Look of your desire.

**View Transforms**

The config includes the following view transform:
- `Guard Rail`The minimalist image formation that only touches "the invalid", replaces Blender's legacy "Standard".
- `AgX` The Filmic-like sigmoid based image formation with 16.5 stops of dynamic range.
- `AgX Log` The Log encoding with chroma-inset and rotation of primaries included. Uses BT.2020 primaries with Log 2 encoding from `-12.47393` to `12.5260688117` and I-D65 white point.
- `AgX False Color` A heat-map-like imagery derived from `AgX`'s formed image. uses BT.2020's CIE 2012 luminance for luminance coefficients evaluation. 

** False Color ranges
Different from False Color in current Blender or the Filmic-Blender config, the false color here is a post-formation closed domain evaluation. Therefore all values below will be linearized 0 to 1 value written in percentage.

    | [0.0, 1.0] Closed Domain Linear | Color |
    | ---- | ---- |
    | Low Clip | Black |
    | 0.0001% to 0.05% | Blue |
    | 0.05% to 0.5% | Blue-Cyan |
    | 0.5% to 5% | Cyan |
    | 5% to 16% | Green-Cyan |
    | 16% to 22% | Grey |
    | 22% to 35% | Green-Yellow |
    | 35% to 55% | Yellow |
    | 55% to 80% | Orange |
    | 80% to 97% | Red |
    | High Clip | White |


**Looks**
Looks are artistic adjustment to the image formation chain. The artistic adjustment can happen before image formation in the Open Domain, or after the image formation in Closed Domain. This config currently features two pos-formation looks.

- `Punchy` A post-formation look that makes the image look more “punchy”. Technically it’s just a power curve of 1.35 post-formation.

- `Green Ink` A post-formation look that tints the lower range greenish and higher range warm.

- `Greyscale` Turn the image into greyscale. Luminance coefficients are BT.2020’s CIE 2012 values, evaluated in Linear state.

-  Five Contrast Looks. Similar to Filmic’s contrast looks. All operates in AgX Log, with pivot set in 0.18 middle grey. All using OCIO v2’s `Grading Primary Transform` feature, meaning you can customize your contrast just by editing the values in the config.

**Colorimetric Information**

- `Reference` Every OCIO config has their own reference space, all other spaces are defined with how they transform “from” and/or “to” the reference space.  While Blender’s previous config has been using `Linear BT.709 I-D65` as reference, this config uses `1931 CIE XYZ E white point chromaticity` as reference. This is a sane decision, since CIE XYZ is the root for everything else color management related. FilmLight’s TCAMv2 config also has CIE XYZ as reference. 

- `AgX Base image formation space` The AgX in this config has one single image formed in the BT.2020 display medium, then the images for other mediums are produced from the formed image in BT.2020.

- Supported Image Display Mediums:

  - `sRGB`, Generic sRGB / REC.709 displays with 2.2 native power function
  - `BT.1886`, Generic sRGB / REC.709 displays with 2.4 native power function
  - `Display P3` P3 displays with 2.2 native power function. Examples include:
    Apple MacBook Pros from 2016 on.
    Apple iMac Pros.
    Apple iMac from late 2015 on.
  - `BT.2020`BT.2020 displays with 2.4 native power function.

It's very unlikely someone would use a BT.2020 2.4 display as of now, but since we have the image formed in BT.2020, supporting it is just a "why not?" thing to do.


-`Colorspaces`
  This config supports the following colorspaces:
  - `Linear CIE-XYZ I-E` This is the standard 1931 CIE chromaticity standard used as reference.
- `Linear CIE-XYZ I-D65` This is the chromatic-adaptated to I-D65 version of the XYZ chromaticity. Method used is `Bradford`
- `Linear BT.709 I-E` Open Domain Linear BT.709 Tristimulus with I-E white point
- `Linear BT.709 I-D65` Open Domain Linear BT.709 Tristimulus with I-D65 white point
- `Linear DCI-P3 I-E` Open Domain Linear P3 Tristimulus with I-E white point
- `Linear DCI-P3 I-D65` Open Domain Linear P3 Tristimulus with I-D65 white point
- `Linear BT.2020 I-E` Open Domain Linear BT.2020 Tristimulus with I-E white point
- `Linear BT.2020 I-D65` Open Domain Linear BT.2020 Tristimulus with I-D65 white point
- `ACES2065-1` Open Domain AP0 Tristimulus with ACES white point
- `ACEScg` Open Domain AP1 Tristimulus with ACES white point
- `Linear E-Gamut I-D65` Open Domain Linear E Gamut Tristimulus with I-D65 white point

Note: `I-E` is short for “Iluminant E”, `I-D65` is short for “Iluminant D65”.

 - The use of I-E white point
 
    The main reason for supporting the I-E version of the spaces is to be prepared for the upcoming Spectral Cycles. Spectral renderers with capability to input RGB textures require an I-E based RGB working space to ensure an error-free spectral reconstruction/upsampling process. 

    Note for using Eary’s AgX for Spectral Cycles: Remember to change the XYZ role to the I-E version of the XYZ chromaticity.   

