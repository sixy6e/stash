module topo_shadow
    implicit none
    ! Author Josh Sixsmith; joshua.sixsmith@ga.gov.au
contains

    subroutine cast_shadow_geo(DEM, mask, dy, dx, zenith, k_max, &
         az_case, d0, pi, zmax, xoff, yoff, cosphc, sinphc)

       implicit none

       real, dimension(:,:), intent(in) :: dy, dx
       real, dimension(:,:), intent(in) :: d0, cosphc, sinphc
       integer*2, dimension(:,:), intent(in) :: k_max
       integer*1, dimension(:,:), intent(inout) :: mask, az_case
       real, dimension(:,:), intent(in) :: zenith, DEM
       integer, intent(in) :: xoff, yoff, zmax
       real, intent(in) :: pi

       integer, parameter :: k_setting=1500
       integer :: i, j, k, ipos, jpos, ii, jj, rows, cols
       integer :: kmx, az, m
       real :: t, tt, test, htol, yd, xd, zpos
       real :: m_inc(k_setting), n_inc(k_setting), h_offset(k_setting)
       real :: cos_phc, sin_phc, zen, d_0
       real, dimension(size(mask,1),size(mask,2)) :: on_dx, on_dy

       htol = 1.0
       rows = size(mask, 1)
       cols = size(mask, 2)
       on_dx = (1.0/dx) * cosphc
       on_dy = (1.0/dy) * sinphc

       ! The DEM is a larger array than mask, solar_zen, k_mask, 
       ! az_case, d0, cosphc, sinphc, dy, dx which are all the same
       ! size. Those other arrays fit within the DEM specified by xoff
       ! & yoff.

       do j = 1, cols
           jj = j + xoff
           do i = 1, rows
               ii = i + yoff
               kmx = k_max(i,j)
               cos_phc = on_dx(i,j)
               sin_phc = on_dy(i,j)
               zen = zenith(i,j)
               t = DEM(ii,jj)
               az = az_case(i,j)
               d_0 = d0(i,j)
               m = mask(i,j)
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
   end subroutine cast_shadow_geo

    subroutine cast_shadow_prj(DEM, mask, dy, dx, zenith, k_max, &
         az_case, d0, pi, zmax, xoff, yoff, cosphc, sinphc)

       implicit None

       integer*2, dimension(:,:), intent(in) :: k_max
       integer*1, dimension(:,:), intent(inout) :: mask, az_case
       real, dimension(:,:), intent(in) :: zenith, DEM
       real, dimension(:,:), intent(in) :: d0, cosphc, sinphc
       integer, intent(in) :: xoff, yoff, zmax
       real, intent(in) :: pi
       real, intent(in) :: dy, dx

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

       do j = 1, cols
           jj = j + xoff
           do i = 1, rows
               ii = i + yoff
               kmx = k_max(i,j)
               cos_phc = cosphc(i,j) * on_dx
               sin_phc = sinphc(i,j) * on_dy
               zen = zenith(i,j)
               t = DEM(ii,jj)
               az = az_case(i,j)
               d_0 = d0(i,j)
               m = mask(i,j)
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
end module topo_shadow
