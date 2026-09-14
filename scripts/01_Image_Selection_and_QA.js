/**************************************************************
 Script Name : 01_Image_Selection_and_QA

 Purpose:
 - Search Sentinel-2 imagery
 - Mosaic intersecting Sentinel-2 tiles
 - Clip imagery to the Kapuas Delta AOI
 - Retrieve image metadata
 - Support image selection for VedgeSat validation

 Author : Sulastri Prihandini
 University : University of Glasgow
**************************************************************/


//==============================================================
// 1. IMPORT AOI
//==============================================================

// Import your AOI from the Assets panel.
// After clicking "Import", Earth Engine creates "table".

var AOI = table;


//==============================================================
// 2. DISPLAY AOI
//==============================================================

Map.centerObject(AOI, 11);

Map.addLayer(
  AOI.style({
    color: 'red',
    fillColor: '00000000',
    width: 2
  }),
  {},
  'Kapuas Delta AOI'
);


//==============================================================
// 3. CANDIDATE SENTINEL-2 DATES
//==============================================================
//
// Dates selected based on:
// 1. Seasonal representation
// 2. Minimal cloud over the AOI
// 3. Shortest interval to PlanetScope imagery

var dates = [

{
  season: 'Wet',
  date: '2025-03-24'
},

{
  season: 'Transition (Wet–Dry)',
  date: '2026-04-18'
},

{
  season: 'Dry',
  date: '2025-09-30'
},

{
  season: 'Transition (Dry–Wet)',
  date: '2025-11-14'
}

];


//==============================================================
// 4. RGB VISUALISATION
//==============================================================

var rgbVis = {

bands: ['B4','B3','B2'],

min: 0,

max: 3000

};


//==============================================================
// 5. LOOP THROUGH EACH DATE
//==============================================================

dates.forEach(function(item){

var season = item.season;
var date = item.date;

print('=================================================');

print('SEASON:', season);
print('DATE:', date);


//--------------------------------------------------------------
// Search Sentinel-2
//--------------------------------------------------------------

var images = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')

.filterBounds(AOI)

.filterDate(
    date,
    ee.Date(date).advance(1,'day')
);


//--------------------------------------------------------------
// Number of images
//--------------------------------------------------------------

print('Number of images:', images.size());


//--------------------------------------------------------------
// Convert ImageCollection into List
//--------------------------------------------------------------

var imageList = images.toList(images.size());

var count = images.size().getInfo();


//--------------------------------------------------------------
// Print metadata for every image
//--------------------------------------------------------------

for(var i=0; i<count; i++){

var img = ee.Image(imageList.get(i));

print('------------------------------');

print('Image:', i+1);

print('Tile:',
img.get('MGRS_TILE'));

print('Cloud (%):',
img.get('CLOUDY_PIXEL_PERCENTAGE'));

print('Acquisition Time:',
ee.Date(img.get('system:time_start')));

}


//--------------------------------------------------------------
// Create Mosaic
//--------------------------------------------------------------

var mosaic = images

.mosaic()

.clip(AOI);

//--------------------------------------------------------------
// Display Sentinel-2 Tile Footprints (Quality Assessment)
//--------------------------------------------------------------

var colors = ['yellow', 'cyan', 'magenta', 'lime'];

for (var i = 0; i < count; i++) {

  var img = ee.Image(imageList.get(i));

  Map.addLayer(
    img.geometry(),
    {
      color: colors[i % colors.length]
    },
    season + ' - Footprint ' + (i + 1),
    false
  );
}

//--------------------------------------------------------------
// Display Mosaic
//--------------------------------------------------------------

Map.addLayer(

mosaic,

rgbVis,

season + ' (' + date + ')',

true

);

});


//==============================================================
// 6. END OF SCRIPT
//==============================================================
