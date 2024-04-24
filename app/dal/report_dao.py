
class ReportDAO:
    """
    This class is a Data Access Object (DAO) that is responsible for running reports.
    """
    def run_report(self, report_id: int)->tuple:
        """
        This method runs a report and returns the column titles and data rows.
        """
        column_titles = []
        data = []

        # TODOO: Implement the code to run the report for the given report_id
        # The report_id is used to determine the report to run
        # The report_id is used to determine the column titles and data rows to return
        match(report_id):
            case 0:
                column_titles = ['Column 1', 'Column 2'] 
                data = []
            case 1:
                column_titles = ['Column 1', 'Column 2', 'Column 3']   
                data = []
            case 2:
                column_titles = ['Column 1', 'Column 2', 'Column 3', 'Column 4'] 
                data = []
            case 3:
                column_titles = ['Column 1', 'Column 2', 'Column 3', 'Column 4', 'Column 5'] 
                data = []  
            case 4:
                column_titles = ['Column 1', 'Column 2', 'Column 3', 'Column 4', 'Column 5', 'Column 6'] 
                data = []  

        return column_titles, data
        

