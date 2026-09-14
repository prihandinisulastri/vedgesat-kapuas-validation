/**************************************************************
 Script Name : 02_Sentinel2_Export

 Purpose:
 Export seasonal Sentinel-2 mosaics for VedgeSat validation

 Author:
 Sulastri Prihandini
 University of Glasgow
**************************************************************/

//==============================================================
// 1. IMPORT AOI
//==============================================================

var AOI = table.geometry();

Map.centerObject(AOI, 11);
Map.addLayer(AOI, {color:'red'}, 'Kapuas Delta AOI');


//==============================================================
// 2. RGB VISUALIZATION
//==============================================================

var rgbVis = {
  bands:['B4','B3','B2'],
  min:0,
  max:3000
};


//==============================================================
// 3. SELECTED DATES
//==============================================================

var dates = [

{
  season:'Wet',
  date:'2025-03-24'
},

{
  season:'Transition_WetDry',
  date:'2026-04-18'
},

{
  season:'Dry',
  date:'2025-09-30'
},

{
  season:'Transition_DryWet',
  date:'2025-11-14'
}

];


//==============================================================
// 4. EXPORT LOOP
//==============================================================

dates.forEach(function(item){

  var season = item.season;
  var date = item.date;

  print('Exporting:', season);

  //----------------------------------------------------------
  // Load Sentinel-2
  //----------------------------------------------------------

  var images = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')

      .filterBounds(AOI)

      .filterDate(
          date,
          ee.Date(date).advance(1,'day')
      );

  //----------------------------------------------------------
  // Create Mosaic
  //----------------------------------------------------------

  var mosaic = images
    .mosaic()
    .select([
      'B2',
      'B3',
      'B4',
      'B5',
      'B6',
      'B7',
      'B8',
      'B8A',
      'B11',
      'B12'
    ])
    .clip(AOI);

  //----------------------------------------------------------
  // Display
  //----------------------------------------------------------

  Map.addLayer(
      mosaic,
      rgbVis,
      season,
      false
  );

  //----------------------------------------------------------
  // Export
  //----------------------------------------------------------

  Export.image.toDrive({

      image:mosaic,

      description:season,

      folder:'VedgeSat_Sentinel2',

      fileNamePrefix:season + '_' + date,

      region:AOI,

      scale:10,

      crs:'EPSG:32749',

      maxPixels:1e13

  });

});
