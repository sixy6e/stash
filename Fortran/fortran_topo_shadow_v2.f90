subroutine cast_shadow_prj(DEM, mask, dy, dx, zenith, k_max, &
     az_case, d0, pi, zmax, xoff, yoff, cosphc, sinphc) 
!subroutine cast_shadow_prj(DEM, mask, dy, dx, zenith, k_max, &
!     az_case, d0, pi, zmax, xoff, yoff, cosphc, sinphc, &
!     dem_x, dem_y, msk_x, msk_y)

   implicit None

   !integer, dimension(:,:), intent(in) :: DEM, k_max, az_case
   !integer, dimension(:,:), intent(in) :: k_max, az_case
   integer*2, dimension(:,:), intent(in) :: k_max
   integer*1, dimension(:,:), intent(inout) :: mask, az_case
   real, dimension(:,:), intent(in) :: zenith, DEM
   real, dimension(:,:), intent(in) :: d0, cosphc, sinphc
   integer, intent(in) :: xoff, yoff, zmax
   !integer, intent(in) :: xoff, yoff, zmax, dem_x, dem_y, msk_x, msk_y
   real, intent(in) :: pi
   real, intent(in) :: dy, dx
   !integer*2, dimension(msk_y,msk_x), intent(in) :: k_max
   !integer*1, dimension(msk_y,msk_x), intent(inout) :: mask, az_case
   !real, dimension(msk_y,msk_x), intent(in) :: zenith
   !real, dimension(dem_y,dem_x), intent(in) :: DEM
   !real, dimension(msk_y,msk_x), intent(in) :: d0, cosphc, sinphc
   !integer*1, dimension(size(mask,1),size(mask,2)), intent(inout) :: mask
   !integer*2, dimension(size(mask,1),size(mask,2)), intent(in) :: k_max
   !integer*1, dimension(size(mask,1),size(mask,2)), intent(inout) :: az_case
   !real, dimension(size(mask,1),size(mask,2)), intent(in) :: zenith
   !real, dimension(size(DEM,1),size(DEM,2)), intent(in) :: DEM
   !real, dimension(size(mask,1),size(mask,2)), intent(in) :: d0, cosphc, sinphc

   integer, parameter :: k_setting=1500
   integer :: i, j, k, ipos, jpos, ii, jj, rows, cols
   integer :: kmx, az, m
   real :: t, tt, test, htol, yd, xd, zpos
   real :: m_inc(k_setting), n_inc(k_setting), h_offset(k_setting)
   real :: cos_phc, sin_phc, zen, d_0, on_dx, on_dy


   htol = 1.0
   rows = size(mask, 1)
   cols = size(mask, 2)
   on_dx = 1.0/dx
   on_dy = 1.0/dy
   
   ! The DEM is a larger array than mask, solar_zen, k_mask,
   ! az_case, d0, cosphc, sinphc which are all the same size.
   ! Those other arrays fit within the DEM with an offset specified
   ! by xoff & yoff.


   print *, "The code appears to have passed the arguments"
   print *, "pi: ", pi
   print *, "dem(100,100): ", dem(100,100)
   print *, "cols, rows", cols, rows
   print *, "mask(100,100): ", mask(100,100)
   print *, "dx: ", dx
   print *, "dy: ", dy
   print *, "zenith(100,100): ", zenith(100,100)
   print *, "dx*2: ", dx * 2
   print *, "dx/2: ", dx / 2
   print *, "dx .gt. 2: ", dx .gt. 2
   print *, "dx .lt. 2: ", dx .lt. 2

   !do i = 1, rows
   do j = 1, cols
       !ii = i + yoff
       jj = j + xoff
       !do j = 1, cols
       do i = 1, rows
           !ii = i + yoff
           !jj = j + xoff
           ii = i + yoff
           kmx = k_max(i,j)
           cos_phc = cosphc(i,j) * on_dx
           sin_phc = sinphc(i,j) * on_dy
           zen = zenith(i,j)
           t = DEM(ii,jj)
           az = az_case(i,j)
           d_0 = d0(i,j)
           m = mask(i,j)
           !do k = 1, k_max(i,j)
           ! put the 'az if' in the k loop
           ! maybe in python put az as either 1 or 2
           ! case 1 or 4 = 1; case 2 or 3 = 2
           ! this 'if' will send any mask eq 0 to iterate as well
           if ((az .eq. 1) .and. (m .eq. 1)) then
               do k = 1, kmx
                   h_offset(k) = float(k) * d_0
                   n_inc(k) = h_offset(k) * cos_phc
                   m_inc(k) = -h_offset(k) * sin_phc
                   h_offset(k) = h_offset(k) * tan(pi/2.0 - zen)
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
                           mask(i,j) = 0
                       endif
                   endif
               enddo
           else if ((az .eq. 2) .and. (m .eq. 1)) then
               ! az is 2 or 3
               do k = 1, kmx
                   h_offset(k) = float(k) * d_0
                   n_inc(k) = -h_offset(k) * cos_phc
                   m_inc(k) = h_offset(k) * sin_phc
                   h_offset(k) = h_offset(k) * tan(pi/2.0 - zen)
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
                           mask(i,j) = 0
                       endif
                   endif
               enddo
           endif
       enddo
   enddo
end subroutine cast_shadow_prj

