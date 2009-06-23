echo building assets
mxmlc -output=fbair/styles/bin/size_large.css.swf fbair/styles/size_large.css
mxmlc -output=fbair/styles/bin/size_small.css.swf fbair/styles/size_small.css

echo building app
amxmlc -debug=true fbair.mxml
adl app.xml