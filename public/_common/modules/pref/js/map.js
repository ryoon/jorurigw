//<script type="text/javascript">

function PrefMap(id, lat, lng, zoom) {
  this.id            = id;
  this.lat           = lat;
  this.lng           = lng;
  this.zoom          = zoom;
  this.centerDisplay = '';
  this.zoomDisplay   = '';
  this.clickDisplay  = '';
  this.clickAddMarker = null;
  this.markers       = new Array();
  
  this.mapWidth      = '600';
  this.mapHeight     = '300';
  
  this.lastAddMarker = null;
  
  var _this = this;
  PrefMap.addEvent(window, 'load', function(){ _this.render() });
  
  this.addMarker = function(lat, lng, msg, key) {
    if (key == 'undefined' || !key) {
      this.markers.push({ marker: new GMarker(new google.maps.LatLng(lat, lng)), msg: msg });
    } else {
      this.markers[key] = { marker: new GMarker(new google.maps.LatLng(lat, lng)), msg: msg };
    }
  }
  
  this.render = function() {
    if (!GBrowserIsCompatible()) {
      return;
    }
    this.map = new GMap2(document.getElementById(this.id), {size:new GSize(this.mapWidth, this.mapHeight)});
    this.map.addControl(new GLargeMapControl());
    //this.map.addControl(new GMapTypeControl());
    this.map.setCenter(new GLatLng(this.lat, this.lng), this.zoom);
    
    for (arrKey in this.markers) {
      if (typeof(this.markers[arrKey]) == 'object') {
          this.renderMarker(this.markers[arrKey]['marker'], this.markers[arrKey]['msg']);
      }
    }
    
    var t = this;
    if (this.centerDisplay != '') {
      t.syncro(t.centerDisplay, t.map.getCenter());
      GEvent.addListener(this.map, 'moveend', function(){
        t.syncro(t.centerDisplay, t.map.getCenter());
      });
    }
    if (this.zoomDisplay != '') {
      document.getElementById(t.zoomDisplay).value = t.map.getZoom();
      GEvent.addListener(this.map, 'zoomend', function(oldLevel, newLevel) {
        document.getElementById(t.zoomDisplay).value = newLevel;
      });
    }
    if (this.clickDisplay != '') {
      GEvent.addListener(this.map, 'click', function(overlay, point) {
        t.syncro(t.clickDisplay, point);
      });
    }

    if (this.clickAddMarker) {
      google.maps.Event.addListener(this.map, "click", function(overlay, point){
        if(overlay==null){
          if (this.lastAddMarker) {
            //last added marker delete
            //t.map.removeOverlay(this.lastAddMarker);
          }
          var m = new GMarker(point);
          t.map.addOverlay(m);
          this.lastAddMarker = m;
        }else{
          //delete marker
          //t.map.removeOverlay(overlay);
        }
      });
    }
  }
  
  this.renderMarker = function(marker, msg) {
    google.maps.Event.addListener(marker, "click", function() {
      marker.openInfoWindowHtml(msg);
    });
    this.map.addOverlay(marker);
  }
  
  this.syncro = function(id, point) {
    if (point == 'undefined' || !point) {
      return false;
    }
    document.getElementById(id + 'Lat').value = point.lat();
    document.getElementById(id + 'Lng').value = point.lng();
  }
  
  this.viewMarker = function(key) {
    if (key == 'undefined' || !key) {
      return false;
    }
    var dispMarker = this.markers[key];
    if (dispMarker == 'undefined' || !dispMarker) {
      return false;
    }
    this.renderMarker(dispMarker['marker'], dispMarker['msg']);
  }
  
  this.removeMarker = function(key) {
    if (key == 'undefined' || !key) {
      return false;
    }
    var rmMarker = this.markers[key];
    if (rmMarker == 'undefined' || !rmMarker) {
      return false;
    } else {
      this.map.removeOverlay(this.markers[key]['marker']);
      delete this.markers[key];
    }
  }
  
}

function PrefMap_init(apiKey) {
  var src = 'http://maps.google.com/maps?file=api&amp;v=2&amp;key=' + apiKey;
  document.write('<' + 'script type="text/javascript" src="' + src + '"' +'><' + '/script>');
}
PrefMap.init = PrefMap_init;

function PrefMap_addEvent(element, listener, func){
  try {
    element.addEventListener(listener, func, false);
  } 
  catch (e) {
    element.attachEvent('on' + listener, func);
  }
}
PrefMap.addEvent = PrefMap_addEvent;
