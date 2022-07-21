module mpi_error_handler_mod
  use mpi, only : mpi_comm_world, mpi_error_string, mpi_abort, mpi_max_error_string, mpi_success
  use logging_mod, only : LOG_ERROR, LOG_INFO, log_log 
  use conversions_mod, only : conv_to_string
  implicit none

  public check_mpi_success
contains

  subroutine check_mpi_success(ierr, length, temp, message, mod_name, sub_name)
    integer :: ierr, length, temp
    character (len = mpi_max_error_string) :: message
    character :: mod_name, sub_name
     
     
    if (ierr /= mpi_success) then
      call mpi_error_string(ierr, message, length, temp)
      call log_log(LOG_ERROR, "MPI error message: "//message//" with error code: "//conv_to_string(ierr))
      call log_log(LOG_ERROR, "MPI error has occurred, check status called from "//mod_name//" and subroutine"//sub_name)
      call mpi_abort(mpi_comm_world, 1, temp)
!    else
!      call log_log(LOG_INFO, "MPI check returned success")
    end if
  end subroutine check_mpi_success
end module mpi_error_handler_mod


