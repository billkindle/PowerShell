# This function will copy output directly to your clipboard.
# Created by: Bill Kindle
# Created on: 2018-12-30 10:43:47 -0500
# Blog: https://billkindle.github.io
function Copy-CurrentDateTimeZoneString {

    Get-Date -UFormat "%Y-%m-%d %T %Z00" | clip
    # the zero's were intentional, but they can be removed if you like.
}