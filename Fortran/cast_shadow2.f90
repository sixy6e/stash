module topographic
    implicit none
contains

    subroutine cast_shadow(DEM, cols, rows, sub_col, sub_row, &
            mask, dy, dx, zenith, lat, lon, k_max, az_case, d0, &
            pi, zmax, l_xoff, l_yoff, cosphc, sinphc)

         integer, intent(in) :: cols, rows, sub_col, sub_row
         integer, dimension(rows, cols), intent(in) :: DEM
         integer*1, dimension(rows, cols), intent(inout) :: mask
         real, dimension(rows, cols), intent(in) :: dy
         real, dimension(rows, cols), intent(in) :: dx
         real, dimension(rows, cols), intent(in) :: zenith
         real, dimension(rows, cols), intent(in) :: lat
         real, dimension(rows, cols), intent(in) :: lon
         integer, dimension(rows, cols), intent(in) :: k_max
         integer, dimension(rows, cols), intent(in) :: az_case
         real, dimension(rows, cols), intent(in) :: d0
         real, dimension(rows, cols), intent(in) :: cosphc
         real, dimension(rows, cols), intent(in) :: sinphc
         !!integer, intent(in) :: cols, rows, sub_col, sub_row
         integer, intent(in) :: l_xoff, l_yoff, zmax
         double precision, intent(in) :: pi

!f2py integer, intent(in) :: cols, rows, sub_col, sub_row
!f2py integer, dimension(rows, cols), intent(in) :: DEM
!f2py integer*1, dimension(rows, cols), intent(inout) :: mask
!f2py real, dimension(rows, cols), intent(in) :: dy
!f2py real, dimension(rows, cols), intent(in) :: dx
!f2py real, dimension(rows, cols), intent(in) :: zenith
!f2py real, dimension(rows, cols), intent(in) :: lat
!f2py real, dimension(rows, cols), intent(in) :: lon
!f2py integer, dimension(rows, cols), intent(in) :: k_max
!f2py integer, dimension(rows, cols), intent(in) :: az_case
!f2py real, dimension(rows, cols), intent(in) :: d0
!f2py real, dimension(rows, cols), intent(in) :: cosphc
!f2py real, dimension(rows, cols), intent(in) :: sinphc
!f2py integer, intent(in) :: l_xoff, l_yoff, zmax
!f2py double precision, intent(in) :: pi


         integer, parameter :: k_setting=1500
         integer :: i, j, k, ipos, jpos, ii, jj
         real :: t, tt, test, htol, yd, xd, zpos
         real :: m_inc(k_setting), n_inc(k_setting), h_offset(k_setting)

         htol = 1.0

         do i = 1, sub_row
             do j = 1, sub_col
                 ii = i + l_yoff
                 jj = j + l_xoff
                 do k = 1, k_max(ii,jj)
                     h_offset(k) = float(k) * d0(ii,jj)
                     if ((az_case(ii,jj) .eq. 1) .or. &
                         (az_case(ii,jj) .eq. 4)) then
                         n_inc(k) = h_offset(k)*cosphc(ii,jj)/dx(ii,jj)
                         m_inc(k) = -h_offset(k)*sinphc(ii,jj)/dy(ii,jj)
                     else
                         n_inc(k) = -h_offset(k)*cosphc(ii,jj)/dx(ii,jj)
                         m_inc(k) = h_offset(k)*sinphc(ii,jj)/dy(ii,jj)
                     endif
                     !h_offset2(k) = h_offset(k) * tan(pi/2.0 - &
                                    !zenith(ii,jj))
                     h_offset(k) = h_offset(k) * tan(pi/2.0 - &
                                    zenith(ii,jj))
                     t = DEM(i,j)
                     tt = t + h_offset(k)
                     if (tt .le. zmax + htol) then
                         ipos = ifix(float(ii) + m_inc(k))
                         jpos = ifix(float(jj) + n_inc(k))
                         yd = float(ii) + m_inc(k) - float(ipos)
                         xd = float(jj) + n_inc(k) - float(jpos)
                         zpos = DEM(ipos,jpos) * (1.0-yd) * (1.0-xd) + &
                              DEM(ipos,jpos+1) * xd * (1.0-yd) + &
                              DEM(ipos+1,jpos+1) * xd * yd + &
                              DEM(ipos+1,jpos) * (1.0-xd) * yd
                         test = tt - zpos
                         if (test .le. htol) then
                             mask(ii,jj) = 0
                         endif
                     endif
                 enddo
             enddo
         enddo
    end subroutine cast_shadow

end module topographic
