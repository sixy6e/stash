subroutine cast_shadow(DEM, cols, rows, sub_col, sub_row, &
            mask, dy, dx, zenith, lat, lon, k_max, az_case, d0, &
            pi, zmax, l_xoff, l_yoff, cosphc, sinphc)

! it might be better to pass in the array dims as well
      implicit none

      integer, parameter :: k_setting=1500
      !integer :: k_setting=1500

      !real, intent(in) :: pi, zmax
      integer, intent(in) :: zmax
      double precision, intent(in) :: pi
      !integer, intent(in) :: cols, rows, sub_col, sub_row
      integer, intent(in) :: cols, rows
      integer, intent(in) :: sub_col, sub_row
      integer, intent(in) :: l_xoff, l_yoff
      integer, dimension(rows, cols), intent(in) :: DEM, az_case
      !integer, dimension(rows, cols), intent(in), depend(rows, cols) &
      !:: DEM, az_case
      integer, intent(in) :: k_max(rows, cols)
      byte, intent(inout) :: mask(rows, cols)
      !integer, intent(in) :: az_case(dem_rows, dem_cols)
      !real, intent(in) :: cosphc(dem_rows, dem_cols)
      !real, intent(in) :: sinphc(dem_rows, dem_cols)
      real, dimension(rows, cols), intent(in) :: cosphc, sinphc
      real, dimension(rows, cols), intent(in) :: zenith, dx, dy
      real, dimension(rows, cols), intent(in) :: lat, lon, d0
      integer :: i, j, k, ipos, jpos, ii, jj
      real :: t, tt, test, htol, m_inc(k_setting), n_inc(k_setting)
      real :: h_offset(k_setting) !, h_offset2(k_setting)
      real :: yd, xd, zpos


      htol = 1.0

      do i = 1, sub_row
          do j = 1, sub_col
              ii = i + l_yoff
              jj = j + l_xoff
              do k = 1, k_max(ii,jj)
                  h_offset(k) = float(k) * d0(ii,jj)
                  if ((az_case(ii,jj) .eq. 1) .or. & 
                      (az_case(ii,jj) .eq. 4)) then
                      n_inc(k) = h_offset(k) * cosphc(ii,jj)/dx(ii,jj)
                      m_inc(k) = - h_offset(k) * sinphc(ii,jj)/dy(ii,jj)
                  else
                      n_inc(k) = - h_offset(k) * cosphc(ii,jj)/dx(ii,jj)
                      m_inc(k) = h_offset(k) * sinphc(ii,jj)/dy(ii,jj)
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
