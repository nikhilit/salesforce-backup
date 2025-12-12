public class DateRangeFromatter {
    public static String formatDateRange(Date toDate, Date fromDate) {
        // Extracting the month names in short form
        String toMonth = getShortMonthName(toDate.month());
        String fromMonth = getShortMonthName(fromDate.month());
        
        // Extracting the years
        Integer toYear = toDate.year();
        Integer fromYear = fromDate.year();
        
        // If both dates are in the same month and year, return single formatted output
        if (toMonth == fromMonth && toYear == fromYear) {
            return toMonth + ' ' + toYear;
        }
        
        // Formatting the result for different months or years
        return toMonth + ' ' + toYear + ' - ' + fromMonth + ' ' + fromYear;
    }
    
    // Helper method to get the short month name from the month number
    public static String getShortMonthName(Integer month) {
        List<String> months = new List<String>{
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        };
        return months[month - 1]; // Adjusting for 1-based indexing
    }
}