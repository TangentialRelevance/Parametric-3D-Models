// This creates a simple vertical stand to hold the build plates for a Bambu Lab X2D 3D printer or any of the other model that shares the 256mm × 256mm plates.
// It has several configurable parameters; the number of plates can be set from 2 to 12, and additional support feet can be added on one or both sides.

/* [Slots] */

// The number of slots in the stand for build plates
Slots = 4; // [2:12]

// The distance, in millimeters, between adjacent slots.  Smaller values reduce the size of the stand, but make it more difficult to grab a given plate.
SlotSpacing = 8; // [3:25]

// The depth of the slots.  This just needs to be enough to hold the plate in place.
SlotDepth = 6; // [3:15]

// How far the stand comes up the side of the plates.  Higher values increase stability boy holding the plate more vertically.
SlotHeight = 30; // [20:200]

/* [Feet] */

// The number of sets of feet to add for stability.  Higher values for 'Slots' and 'SlotSpacing' make the stand deeper, reducing the need for additional feet.  Can set to 0 for no feet.
Feet = 2; // [0, 1, 2]

// Whether both sides of the body have feet.  Set to false if the stand is going to be placed up against something.
DoubleSided = true;

// The width, in millimeters, of the support feet.
FootWidth = 20; // [12:50]

// The length, in millimeters, of the support feet.  Lower values for 'Slots' and 'SlotSpacing' make the stand narrower, requiring the support feet to be longer.
FootLength = 40; // [20:100]

/* [Hidden] */

// Values from the measurements of the X2D build plate
PlateWidth = 256; // The actual width of the build plate
PlateHeight = 256; // The actual height of the build plate without protrusions
PlateTabWidth = 70; // The actual width of the tab where it joins the plate
PlateTabDepth = 8; // The depth by which the tab protrudes from the plate edge
TabSlope = 1; // The angle at which the tab tapers.  1 means 45 degrees (tan 45° = 1)
SlotThickness = 1.5; // The width of the slots that fit the plates

// General strength and shape values
Clearance = 1; // Amount to expand the acual plate dimensions before cutting slots
Smoothing = 2; // The radius applied to various edges to avoid sharp corners.
FootThickness = 2; // The minimum thickness of the support feet
Outside = 6; // The distance between the edge of the stand and the edge of the plate.  Effectively reduced by clearance.
Bottom = 15; // The distance from the bottom of the plate to the bottom of the stand.  Effectively reduced by clearance.  Must be large enough to support the relief for the plate's tab.

// Some calculated figures
TotalWidth = PlateWidth + 2 * Outside; // The overall width of the stand
TotalThickness = (SlotSpacing + SlotThickness) * Slots; // The overall depth of the stand without feet
SlotCenters = [-(TotalThickness - SlotSpacing) / 2 : SlotSpacing + SlotThickness : TotalThickness / 2]; // Center coordinates for the slots, based on 0 being the center of the stand

OutsideHeight = Bottom + SlotHeight; // The height of the outside of the stand
InsideHeight = Bottom + SlotDepth; // The height of the inside of the stand
OutsideWidth = Outside + SlotDepth; // The width of the outside wings of the stand

module Stand()
{ 
    module OutsideRadius()
    {
        offset(r = Smoothing)
        offset(delta = -Smoothing)
        children();
    }

    module InsideRadius()
    {
        offset(r = -Smoothing)
        offset(delta = Smoothing)
        children();
    }

    module Smooth()
    {
        OutsideRadius()
        InsideRadius()
        children();
    }

    module OutsideCrossSection()
    {
        Smooth()
        union()
        {
            square([TotalWidth, InsideHeight]);
            square([OutsideWidth, OutsideHeight]);
            translate([TotalWidth - OutsideWidth, 0]) square([OutsideWidth, OutsideHeight]);
        }
    }

    module PlateCrossSection()
    {
        // Calculate the X coordinates for the tab trapezoid
        TabX1 = (PlateWidth - PlateTabWidth) / 2;
        TabX4 = TabX1 + PlateTabWidth;
        TabX2 = TabX1 + PlateTabDepth * TabSlope;
        TabX3 = TabX4 - PlateTabDepth * TabSlope;

        translate([Outside, Bottom])
        Smooth()
        offset(delta = Clearance) 
        polygon([
            [0, 0],
            [TabX1, 0],
            [TabX2, -PlateTabDepth],
            [TabX3, -PlateTabDepth],
            [TabX4, 0],
            [PlateWidth, 0],
            [PlateWidth, PlateHeight],
            [0, PlateHeight],
        ]);
    }

    module Feet()
    {
        // Create a mirrored copy if we're doing double sided feet
        module DoubleSide()
        {
            children();
            if (DoubleSided) mirror([0, 1]) children();
        }

        FootSpacing = TotalWidth / Feet;
        FootCenterCoordinates = [FootSpacing / 2 : FootSpacing : TotalWidth];
        FootStartCoordinates = [for (foot = FootCenterCoordinates) foot - FootWidth / 2];
        FootExtent = FootLength + TotalThickness / 2; // The extent of the foot measured from the center of the body

        // Build the flat part of the feet     
        linear_extrude(FootThickness)
        OutsideRadius()
        InsideRadius()
        union()
        {
            for(foot = FootStartCoordinates)
            {
                translate([foot, 0])
                DoubleSide()
                square([FootWidth, FootExtent]);
            }
          
            translate([TotalWidth / 2, 0])
            square([TotalWidth - 2 * Smoothing, TotalThickness], center = true);
        }

        // Build the stiffness ribs for the feet
        EllipseSemiMinor = InsideHeight - FootThickness;
        EllipseSemiMajor = FootLength;
        EllipseAspectRatio = EllipseSemiMajor / EllipseSemiMinor;

        for(foot = FootCenterCoordinates)
        {
            translate([foot, 0, FootThickness])
            rotate([0, -90, 0])
            linear_extrude(FootThickness, center = true)
            DoubleSide()
            difference()
            {
              square([EllipseSemiMinor, FootExtent]);

              translate([EllipseSemiMinor, FootExtent])
              scale([1, EllipseAspectRatio])
              circle(r = EllipseSemiMinor);
            }
        }
    }

    difference()
    {
        union()
        {
            rotate([90, 0, 0])
            linear_extrude(TotalThickness, center = true)
            OutsideCrossSection();
            
            Feet();
        }
        
        rotate([90, 0, 0])
        for(slot = SlotCenters)
        {
            translate([0, 0, slot])
            linear_extrude(SlotThickness, center = true)
            PlateCrossSection();
        }
    }
}

render($fn = $preview ? 30 : 360)
{
    Stand();
}
