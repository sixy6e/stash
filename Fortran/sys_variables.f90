module sys_variables
!    contains
    implicit none
!    save
    private
    public pi, d2r, r2d
    double precision, parameter :: pi = 4.0d0*atan(1.0d0)
    double precision, parameter :: d2r = pi/180.0d0
    double precision, parameter :: r2d = 180.0d0/pi

!    pi = 4.0d0*atan(1.0d0)
!    d2r = pi/180.0d0
!    r2d = 180.0d0/pi

end module sys_variables

