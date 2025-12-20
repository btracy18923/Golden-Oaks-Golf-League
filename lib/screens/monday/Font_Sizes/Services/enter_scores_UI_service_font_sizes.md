# Font Sizes - enter_scores_UI_service.dart

## Font Size Methods

### getResponsiveFontSize (91-100)
- 94: return isHeader ? 8.0 : 11.0 (phone)
- 96: return isHeader ? 12.0 : 13.0 (8" tablet)
- 98: return isHeader ? 14.0 : 15.0 (10" tablet)

### getPurseHeaderFontSize (104-106)
- 105: ResponsiveTypography.getLabel(context) * .85

### getTableHeaderFontSize (110-112)
- 111: ResponsiveTypography.getTableHeader(context) * .85

### getGroupHeaderFontSize (116-118)
- 117: ResponsiveTypography.getHeading(context) * .85

### getTableDataFontSize (122-124)
- 123: ResponsiveTypography.getSmall(context) * .85

## Monday League - Purse Header (buildPurseHeader)
- 187: fontSize = getResponsiveFontSize(deviceType, isHeader: true)
- 188: headerFontSize = getPurseHeaderFontSize(context)
- 220: fontSize: headerFontSize
- 237: fontSize: headerFontSize (value background)
- 257: fontSize: headerFontSize
- 271: fontSize: headerFontSize (value background)
- 288: fontSize: headerFontSize
- 302: fontSize: headerFontSize (value background)
- 330: size: fontSize * 1.5 (icon)

## Monday League - Group Components

### Group Header
- 710: groupHeaderFontSize = getGroupHeaderFontSize(context)
- 727: fontSize: groupHeaderFontSize

### Table Headers
- 781: tableHeaderFontSize = getTableHeaderFontSize(context)
- 805: fontSize: tableHeaderFontSize

### Data Cells (buildPlayerCell)
- 941: tableDataFontSize = getTableDataFontSize(context)
- 969: fontSize: tableDataFontSize

### Clickable Cells (buildClickablePlayerCell)
- 981: tableDataFontSize = getTableDataFontSize(context)
- 1015: fontSize: tableDataFontSize

### Input Cells (buildInputCell)
- 1057: tableDataFontSize = getTableDataFontSize(context)
- 1081: fontSize: tableDataFontSize

## Wednesday League - Purse Header (buildWednesdayPurseHeader)
- 1160: headerFontSize = ResponsiveTypography.getLabel(context)
- 1209: fontSize: headerFontSize
- 1219: fontSize: headerFontSize (value background)
- 1225: fontSize: headerFontSize
- 1235: fontSize: headerFontSize (value background)
- 1241: fontSize: headerFontSize
- 1251: fontSize: headerFontSize (value background)
- 1272: size: isPhone ? 18 : 24 (icon)

## Wednesday League - Group Components

### Group Title
- 1554: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold)

### Table Headers
- 1630: ResponsiveTypography.tableHeaderStyle(context, fontWeight: FontWeight.bold)

### Name Cell (with WC badge)
- 1831: fontSize: isPhone ? 8 : 10 (WC badge)
- 1839: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold, color: Colors.blue[700])

### Data Cells
- 1871: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold)

### Gross Input Cell
- 1911: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold)
