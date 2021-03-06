
!========================================================================
!
!                   S P E C F E M 2 D  Version 7 . 0
!                   --------------------------------
!
! Copyright Universite de Pau et des Pays de l'Adour and CNRS, France.
! Contributors: Dimitri Komatitsch, dimitri DOT komatitsch aT univ-pau DOT fr
!               Nicolas Le Goff, nicolas DOT legoff aT univ-pau DOT fr
!               Roland Martin, roland DOT martin aT univ-pau DOT fr
!               Christina Morency, cmorency aT princeton DOT edu
!
! This software is a computer program whose purpose is to solve
! the two-dimensional viscoelastic anisotropic or poroelastic wave equation
! using a spectral-element method (SEM).
!
! This software is governed by the CeCILL license under French law and
! abiding by the rules of distribution of free software. You can use,
! modify and/or redistribute the software under the terms of the CeCILL
! license as circulated by CEA, CNRS and Inria at the following URL
! "http://www.cecill.info".
!
! As a counterpart to the access to the source code and rights to copy,
! modify and redistribute granted by the license, users are provided only
! with a limited warranty and the software's author, the holder of the
! economic rights, and the successive licensors have only limited
! liability.
!
! In this respect, the user's attention is drawn to the risks associated
! with loading, using, modifying and/or developing or reproducing the
! software by the user in light of its specific status of free software,
! that may mean that it is complicated to manipulate, and that also
! therefore means that it is reserved for developers and experienced
! professionals having in-depth computer knowledge. Users are therefore
! encouraged to load and test the software's suitability as regards their
! requirements in conditions enabling the security of their systems and/or
! data to be ensured and, more generally, to use and operate it in the
! same conditions as regards security.
!
! The full text of the license is available in file "LICENSE".
!
!========================================================================

  subroutine compute_forces_poro_fluid(nglob,nspec,myrank,nelemabs,numat, &
               ispec_selected_source,ispec_selected_rec,is_proc_source,which_proc_receiver,&
               source_type,it,NSTEP,anyabs, &
               initialfield,ATTENUATION_VISCOELASTIC_SOLID,ATTENUATION_PORO_FLUID_PART,deltat, &
               ibool,kmato,numabs,poroelastic,codeabs, &
               accelw_poroelastic,velocw_poroelastic,displw_poroelastic,velocs_poroelastic,displs_poroelastic,&
               displs_poroelastic_old,b_accelw_poroelastic,b_displw_poroelastic,b_displs_poroelastic,&
               density,porosity,tortuosity,permeability,poroelastcoef,xix,xiz,gammax,gammaz, &
               jacobian,source_time_function,sourcearray,adj_sourcearrays, &
               e11,e13,hprime_xx,hprimewgll_xx,hprime_zz,hprimewgll_zz,wxgll,wzgll,&
               inv_tau_sigma_nu2,phi_nu2,Mu_nu2,N_SLS, &
               rx_viscous,rz_viscous,theta_e,theta_s,b_viscodampx,b_viscodampz,&
               ibegin_edge1_poro,iend_edge1_poro,ibegin_edge3_poro,iend_edge3_poro, &
               ibegin_edge4_poro,iend_edge4_poro,ibegin_edge2_poro,iend_edge2_poro,&
               C_k,M_k,NSOURCES,nrec,SIMULATION_TYPE,SAVE_FORWARD,&
               b_absorb_poro_w_left,b_absorb_poro_w_right,b_absorb_poro_w_bottom,b_absorb_poro_w_top,&
               nspec_left,nspec_right,nspec_bottom,nspec_top,ib_left,ib_right,ib_bottom,ib_top,f0,freq0,Q0, &
               e11_LDDRK,e13_LDDRK,alpha_LDDRK,beta_LDDRK, &
               e11_initial_rk,e13_initial_rk,e11_force_RK, e13_force_RK, &
               stage_time_scheme,i_stage)

! compute forces for the fluid poroelastic part

  implicit none

  include "constants.h"
  integer :: NSOURCES, i_source
  integer, dimension(NSOURCES) ::ispec_selected_source,source_type,is_proc_source
  integer :: nglob,nspec,nelemabs,numat,it,NSTEP
  integer :: nrec,SIMULATION_TYPE,myrank
  integer, dimension(nrec) :: ispec_selected_rec,which_proc_receiver
  integer :: nspec_left,nspec_right,nspec_bottom,nspec_top
  integer, dimension(nelemabs) :: ib_left
  integer, dimension(nelemabs) :: ib_right
  integer, dimension(nelemabs) :: ib_bottom
  integer, dimension(nelemabs) :: ib_top
  integer :: stage_time_scheme,i_stage

  logical :: anyabs,initialfield,ATTENUATION_VISCOELASTIC_SOLID
  logical :: SAVE_FORWARD

  double precision :: deltat

  integer, dimension(NGLLX,NGLLZ,nspec) :: ibool
  integer, dimension(nspec) :: kmato
  integer, dimension(nelemabs) :: numabs,ibegin_edge4_poro,iend_edge4_poro,ibegin_edge2_poro,iend_edge2_poro,&
                                  ibegin_edge1_poro,iend_edge1_poro,ibegin_edge3_poro,iend_edge3_poro

  logical, dimension(nspec) :: poroelastic
  logical, dimension(4,nelemabs)  :: codeabs

  real(kind=CUSTOM_REAL), dimension(NDIM,nglob) :: accelw_poroelastic,velocw_poroelastic,displw_poroelastic,&
                                            displs_poroelastic,displs_poroelastic_old,velocs_poroelastic
  real(kind=CUSTOM_REAL), dimension(NDIM,nglob) :: b_accelw_poroelastic,b_displw_poroelastic,b_displs_poroelastic
  double precision, dimension(2,numat) :: density
  double precision, dimension(3,numat) :: permeability
  double precision, dimension(numat) :: porosity,tortuosity
  double precision, dimension(4,3,numat) :: poroelastcoef
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec) :: xix,xiz,gammax,gammaz,jacobian
  real(kind=CUSTOM_REAL), dimension(NSOURCES,NSTEP,stage_time_scheme) :: source_time_function
  real(kind=CUSTOM_REAL), dimension(NSOURCES,NDIM,NGLLX,NGLLZ) :: sourcearray
  real(kind=CUSTOM_REAL), dimension(nrec,NSTEP,3,NGLLX,NGLLZ) :: adj_sourcearrays
  real(kind=CUSTOM_REAL), dimension(nglob) :: C_k,M_k
  real(kind=CUSTOM_REAL), dimension(NDIM,NGLLZ,nspec_left,NSTEP) :: b_absorb_poro_w_left
  real(kind=CUSTOM_REAL), dimension(NDIM,NGLLZ,nspec_right,NSTEP) :: b_absorb_poro_w_right
  real(kind=CUSTOM_REAL), dimension(NDIM,NGLLX,nspec_top,NSTEP) :: b_absorb_poro_w_top
  real(kind=CUSTOM_REAL), dimension(NDIM,NGLLX,nspec_bottom,NSTEP) :: b_absorb_poro_w_bottom
  real(kind=CUSTOM_REAL), dimension(nglob) :: b_viscodampx,b_viscodampz

  integer :: N_SLS
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec,N_SLS) :: e11,e13
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec,N_SLS) :: e11_LDDRK,e13_LDDRK
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec,N_SLS) :: e11_initial_rk,e13_initial_rk
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec,N_SLS,stage_time_scheme) :: e11_force_RK, e13_force_RK
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec,N_SLS) :: inv_tau_sigma_nu2,phi_nu2
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec) :: Mu_nu2
  real(kind=CUSTOM_REAL) :: e11_sum,e13_sum
  integer :: i_sls

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec) ::dux_dxl_n,duz_dzl_n,duz_dxl_n,dux_dzl_n, &
                                                         !nsub1 denote discrete time step n-1
                                                         dux_dxl_nsub1,duz_dzl_nsub1,duz_dxl_nsub1,dux_dzl_nsub1

! viscous attenuation
  double precision, dimension(NGLLX,NGLLZ,nspec) :: rx_viscous
  double precision, dimension(NGLLX,NGLLZ,nspec) :: rz_viscous
  double precision :: theta_e,theta_s
  logical ATTENUATION_PORO_FLUID_PART
  double precision, dimension(3):: bl_relaxed_viscoelastic,bl_unrelaxed_elastic

! derivatives of Lagrange polynomials
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLX) :: hprime_xx,hprimewgll_xx
  real(kind=CUSTOM_REAL), dimension(NGLLZ,NGLLZ) :: hprime_zz,hprimewgll_zz

! Gauss-Lobatto-Legendre weights
  real(kind=CUSTOM_REAL), dimension(NGLLX) :: wxgll
  real(kind=CUSTOM_REAL), dimension(NGLLZ) :: wzgll

  double precision :: f0,freq0,Q0,w_c

  ! parameters for the LDDRK time scheme
  real(kind=CUSTOM_REAL), dimension(Nstages) :: alpha_LDDRK,beta_LDDRK

  ! temporary variable
  real(kind=CUSTOM_REAL) :: weight_rk


!---
!--- local variables
!---

  integer :: ispec,i,j,k,iglob,ispecabs,ibegin,iend,jbegin,jend,irec,irec_local

! spatial derivatives
  real(kind=CUSTOM_REAL) :: dux_dxi,dux_dgamma,duz_dxi,duz_dgamma
  real(kind=CUSTOM_REAL) :: dwx_dxi,dwx_dgamma,dwz_dxi,dwz_dgamma
  real(kind=CUSTOM_REAL) :: dux_dxl,duz_dxl,dux_dzl,duz_dzl
  real(kind=CUSTOM_REAL) :: dwx_dxl,dwz_dxl,dwx_dzl,dwz_dzl
  real(kind=CUSTOM_REAL) :: b_dux_dxi,b_dux_dgamma,b_duz_dxi,b_duz_dgamma
  real(kind=CUSTOM_REAL) :: b_dux_dxl,b_duz_dxl,b_dux_dzl,b_duz_dzl
  real(kind=CUSTOM_REAL) :: b_dwx_dxi,b_dwx_dgamma,b_dwz_dxi,b_dwz_dgamma
  real(kind=CUSTOM_REAL) :: b_dwx_dxl,b_dwz_dxl,b_dwx_dzl,b_dwz_dzl
  real(kind=CUSTOM_REAL) :: sigma_xx,sigma_xz,sigma_zz
  real(kind=CUSTOM_REAL) :: sigmap
  real(kind=CUSTOM_REAL) :: b_sigma_xx,b_sigma_xz,b_sigma_zz
  real(kind=CUSTOM_REAL) :: b_sigmap
  real(kind=CUSTOM_REAL) :: nx,nz,vx,vz,vn,vxf,vzf,vnf,rho_vpI,rho_vpII,rho_vs,tx,tz,weight,xxi,zxi,xgamma,zgamma,jacobian1D

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ) :: tempx1,tempx2,tempz1,tempz2
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ) :: tempx1p,tempx2p,tempz1p,tempz2p
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ) :: b_tempx1,b_tempx2,b_tempz1,b_tempz2
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ) :: b_tempx1p,b_tempx2p,b_tempz1p,b_tempz2p


! Jacobian matrix and determinant
  real(kind=CUSTOM_REAL) :: xixl,xizl,gammaxl,gammazl,jacobianl

! material properties of the poroelastic medium
  real(kind=CUSTOM_REAL) :: mul_relaxed_viscoelastic,lambdal_relaxed_viscoelastic,lambdalplus2mul_relaxed_viscoel
  double precision :: mul_s,kappal_s,rhol_s
  double precision :: etal_f,kappal_f,rhol_f
  double precision :: mul_fr,kappal_fr,phil,tortl,viscodampx,viscodampz
  double precision :: permlxx,permlxz,permlzz,invpermlxx,invpermlxz,invpermlzz,detk
  double precision :: D_biot,H_biot,C_biot,M_biot,rhol_bar

  real(kind=CUSTOM_REAL) :: mul_G,lambdal_G,lambdalplus2mul_G
  real(kind=CUSTOM_REAL) :: cpIl,cpIIl,csl
  double precision :: cpIsquare,cpIIsquare,cssquare

! for attenuation
  real(kind=CUSTOM_REAL) :: phinu2,tauinvnu2,theta_n_u,theta_nsub1_u
  real(kind=CUSTOM_REAL) :: bb,coef0,coef1,coef2

! implement attenuation
  if(ATTENUATION_VISCOELASTIC_SOLID) then

! compute Grad(displs_poroelastic) at time step n for attenuation
    call compute_gradient_attenuation(displs_poroelastic,dux_dxl_n,duz_dxl_n, &
           dux_dzl_n,duz_dzl_n,xix,xiz,gammax,gammaz,ibool,poroelastic,hprime_xx,hprime_zz,nspec,nglob)

! compute Grad(displs_poroelastic) at time step n-1 for attenuation
    call compute_gradient_attenuation(displs_poroelastic_old,dux_dxl_nsub1,duz_dxl_nsub1, &
           dux_dzl_nsub1,duz_dzl_nsub1,xix,xiz,gammax,gammaz,ibool,poroelastic,hprime_xx,hprime_zz,nspec,nglob)

! update memory variables with fourth-order Runge-Kutta time scheme for attenuation
! loop over spectral elements
  do ispec = 1,nspec

    if (poroelastic(ispec)) then
       do j=1,NGLLZ; do i=1,NGLLX
          theta_n_u = dux_dxl_n(i,j,ispec) + duz_dzl_n(i,j,ispec)
          theta_nsub1_u = dux_dxl_nsub1(i,j,ispec) + duz_dzl_nsub1(i,j,ispec)

          ! loop on all the standard linear solids
          do i_sls = 1,N_SLS
            phinu2 = phi_nu2(i,j,ispec,i_sls)
            tauinvnu2 = inv_tau_sigma_nu2(i,j,ispec,i_sls)

            ! update e1, e11, e13 in convolution formation with modified recursive convolution scheme on basis of
            ! second-order accurate convolution term calculation from equation (21) of
            ! Shumin Wang, Robert Lee, and Fernando L. Teixeira,
            ! Anisotropic-Medium PML for Vector FETD With Modified Basis Functions,
            ! IEEE Transactions on Antennas and Propagation, vol. 54, no. 1, (2006)
            ! evolution e1 ! no need since we are just considering shear attenuation
            if(stage_time_scheme == 1) then
              bb = tauinvnu2; coef0 = exp(-bb * deltat)
              if ( abs(bb) > 1e-5_CUSTOM_REAL ) then
                 coef1 = (1._CUSTOM_REAL - exp(-bb * deltat / 2._CUSTOM_REAL)) / bb
                 coef2 = (1._CUSTOM_REAL - exp(-bb* deltat / 2._CUSTOM_REAL)) * exp(-bb * deltat / 2._CUSTOM_REAL)/ bb
              else
                 coef1 = deltat / 2._CUSTOM_REAL
                 coef2 = deltat / 2._CUSTOM_REAL
              endif

              e11(i,j,ispec,i_sls) = coef0 * e11(i,j,ispec,i_sls) + &
                                     phinu2 * (coef1 * (dux_dxl_n(i,j,ispec)-theta_n_u/TWO) + &
                                               coef2 * (dux_dxl_nsub1(i,j,ispec)-theta_nsub1_u/TWO))

              e13(i,j,ispec,i_sls) = coef0 * e13(i,j,ispec,i_sls) + &
                                     phinu2 * (coef1 * (dux_dzl_n(i,j,ispec) + duz_dxl_n(i,j,ispec)) + &
                                               coef2 * (dux_dzl_nsub1(i,j,ispec) + duz_dxl_nsub1(i,j,ispec)))
            endif

            ! update e1, e11, e13 in ADE formation with LDDRK scheme
            ! evolution e1 ! no need since we are just considering shear attenuation
            if(stage_time_scheme == 6) then
              e11_LDDRK(i,j,ispec,i_sls) = alpha_LDDRK(i_stage) * e11_LDDRK(i,j,ispec,i_sls) + &
                                           deltat * ((dux_dxl_n(i,j,ispec)-theta_n_u/TWO) * phinu2) - &
                                           deltat * (e11(i,j,ispec,i_sls) * tauinvnu2)
              e11(i,j,ispec,i_sls) = e11(i,j,ispec,i_sls)+beta_LDDRK(i_stage)*e11_LDDRK(i,j,ispec,i_sls)

              e13_LDDRK(i,j,ispec,i_sls) = alpha_LDDRK(i_stage) * e13_LDDRK(i,j,ispec,i_sls) + &
                                           deltat * ((dux_dzl_n(i,j,ispec) + duz_dxl_n(i,j,ispec))*phinu2) - &
                                           deltat * (e13(i,j,ispec,i_sls) * tauinvnu2)
              e13(i,j,ispec,i_sls) = e13(i,j,ispec,i_sls)+beta_LDDRK(i_stage) * e13_LDDRK(i,j,ispec,i_sls)
            endif

            ! update e1, e11, e13 in ADE formation with classical Runge-Kutta scheme
            ! evolution e1 ! no need since we are just considering shear attenuation
            if(stage_time_scheme == 4) then
              e11_force_RK(i,j,ispec,i_sls,i_stage) = deltat * ((dux_dxl_n(i,j,ispec)-theta_n_u/TWO) * phinu2 - &
                                                                 e11(i,j,ispec,i_sls) * tauinvnu2)
              if(i_stage==1 .or. i_stage==2 .or. i_stage==3)then
                if(i_stage == 1)weight_rk = 0.5_CUSTOM_REAL
                if(i_stage == 2)weight_rk = 0.5_CUSTOM_REAL
                if(i_stage == 3)weight_rk = 1._CUSTOM_REAL

                if(i_stage==1) e11_initial_rk(i,j,ispec,i_sls) = e11(i,j,ispec,i_sls)
                e11(i,j,ispec,i_sls) = e11_initial_rk(i,j,ispec,i_sls) + weight_rk * e11_force_RK(i,j,ispec,i_sls,i_stage)
              else if(i_stage==4)then
                e11(i,j,ispec,i_sls) = e11_initial_rk(i,j,ispec,i_sls) + 1._CUSTOM_REAL / 6._CUSTOM_REAL * &
                                       (e11_force_RK(i,j,ispec,i_sls,1) + 2._CUSTOM_REAL * e11_force_RK(i,j,ispec,i_sls,2) + &
                                        2._CUSTOM_REAL * e11_force_RK(i,j,ispec,i_sls,3) + e11_force_RK(i,j,ispec,i_sls,4))
              endif

              e13_force_RK(i,j,ispec,i_sls,i_stage) = deltat * ((dux_dzl_n(i,j,ispec) + duz_dxl_n(i,j,ispec))*phinu2 - &
                                                                 e13(i,j,ispec,i_sls) * tauinvnu2)
              if(i_stage==1 .or. i_stage==2 .or. i_stage==3)then
                if(i_stage == 1)weight_rk = 0.5_CUSTOM_REAL
                if(i_stage == 2)weight_rk = 0.5_CUSTOM_REAL
                if(i_stage == 3)weight_rk = 1._CUSTOM_REAL
                if(i_stage==1) e13_initial_rk(i,j,ispec,i_sls) = e13(i,j,ispec,i_sls)
                e13(i,j,ispec,i_sls) = e13_initial_rk(i,j,ispec,i_sls) + weight_rk * e13_force_RK(i,j,ispec,i_sls,i_stage)
              else if(i_stage==4)then
                e13(i,j,ispec,i_sls) = e13_initial_rk(i,j,ispec,i_sls) + 1._CUSTOM_REAL / 6._CUSTOM_REAL * &
                                       (e13_force_RK(i,j,ispec,i_sls,1) + 2._CUSTOM_REAL * e13_force_RK(i,j,ispec,i_sls,2) + &
                                        2._CUSTOM_REAL * e13_force_RK(i,j,ispec,i_sls,3) + e13_force_RK(i,j,ispec,i_sls,4))
              endif
            endif
          enddo
        enddo; enddo
     endif
   enddo

  endif ! end of test on attenuation

! loop over spectral elements
  do ispec = 1,nspec

!---
!--- poroelastic spectral element
!---

    if(poroelastic(ispec)) then

! get poroelastic properties of current spectral element
    phil = porosity(kmato(ispec))
    tortl = tortuosity(kmato(ispec))
!solid properties
    mul_s = poroelastcoef(2,1,kmato(ispec))
    kappal_s = poroelastcoef(3,1,kmato(ispec)) -4._CUSTOM_REAL*mul_s/3._CUSTOM_REAL
    rhol_s = density(1,kmato(ispec))
!fluid properties
    kappal_f = poroelastcoef(1,2,kmato(ispec))
    rhol_f = density(2,kmato(ispec))
!frame properties
    mul_fr = poroelastcoef(2,3,kmato(ispec))
    kappal_fr = poroelastcoef(3,3,kmato(ispec)) - 4._CUSTOM_REAL*mul_fr/3._CUSTOM_REAL
    rhol_bar =  (1._CUSTOM_REAL - phil)*rhol_s + phil*rhol_f
!Biot coefficients for the input phi
      D_biot = kappal_s*(1._CUSTOM_REAL + phil*(kappal_s/kappal_f - 1._CUSTOM_REAL))
      H_biot = (kappal_s - kappal_fr)*(kappal_s - kappal_fr)/(D_biot - kappal_fr) + &
                kappal_fr + 4._CUSTOM_REAL*mul_fr/3._CUSTOM_REAL
      C_biot = kappal_s*(kappal_s - kappal_fr)/(D_biot - kappal_fr)
      M_biot = kappal_s*kappal_s/(D_biot - kappal_fr)
!The RHS has the form : div T_f -rho_f/rho_bar div T - eta_fk^-1.partial t w
!where T = G:grad u_s + C_biot div w I
!and T_f = C_biot div u_s I + M_biot div w I
      mul_G = mul_fr
      lambdal_G = H_biot - 2._CUSTOM_REAL*mul_fr
      lambdalplus2mul_G = lambdal_G + TWO*mul_G

! first double loop over GLL points to compute and store gradients
      do j = 1,NGLLZ
        do i = 1,NGLLX


! derivative along x and along z for u_s and w
          dux_dxi = ZERO
          duz_dxi = ZERO

          dux_dgamma = ZERO
          duz_dgamma = ZERO

          dwx_dxi = ZERO
          dwz_dxi = ZERO

          dwx_dgamma = ZERO
          dwz_dgamma = ZERO

          if(SIMULATION_TYPE == 3) then ! kernels calculation
          b_dux_dxi = ZERO
          b_duz_dxi = ZERO

          b_dux_dgamma = ZERO
          b_duz_dgamma = ZERO

          b_dwx_dxi = ZERO
          b_dwz_dxi = ZERO

          b_dwx_dgamma = ZERO
          b_dwz_dgamma = ZERO
          endif

! first double loop over GLL points to compute and store gradients
! we can merge the two loops because NGLLX == NGLLZ
          do k = 1,NGLLX
            dux_dxi = dux_dxi + displs_poroelastic(1,ibool(k,j,ispec))*hprime_xx(i,k)
            duz_dxi = duz_dxi + displs_poroelastic(2,ibool(k,j,ispec))*hprime_xx(i,k)
            dux_dgamma = dux_dgamma + displs_poroelastic(1,ibool(i,k,ispec))*hprime_zz(j,k)
            duz_dgamma = duz_dgamma + displs_poroelastic(2,ibool(i,k,ispec))*hprime_zz(j,k)

            dwx_dxi = dwx_dxi + displw_poroelastic(1,ibool(k,j,ispec))*hprime_xx(i,k)
            dwz_dxi = dwz_dxi + displw_poroelastic(2,ibool(k,j,ispec))*hprime_xx(i,k)
            dwx_dgamma = dwx_dgamma + displw_poroelastic(1,ibool(i,k,ispec))*hprime_zz(j,k)
            dwz_dgamma = dwz_dgamma + displw_poroelastic(2,ibool(i,k,ispec))*hprime_zz(j,k)

          if(SIMULATION_TYPE == 3) then ! kernels calculation
            b_dux_dxi = b_dux_dxi + b_displs_poroelastic(1,ibool(k,j,ispec))*hprime_xx(i,k)
            b_duz_dxi = b_duz_dxi + b_displs_poroelastic(2,ibool(k,j,ispec))*hprime_xx(i,k)
            b_dux_dgamma = b_dux_dgamma + b_displs_poroelastic(1,ibool(i,k,ispec))*hprime_zz(j,k)
            b_duz_dgamma = b_duz_dgamma + b_displs_poroelastic(2,ibool(i,k,ispec))*hprime_zz(j,k)

            b_dwx_dxi = b_dwx_dxi + b_displw_poroelastic(1,ibool(k,j,ispec))*hprime_xx(i,k)
            b_dwz_dxi = b_dwz_dxi + b_displw_poroelastic(2,ibool(k,j,ispec))*hprime_xx(i,k)
            b_dwx_dgamma = b_dwx_dgamma + b_displw_poroelastic(1,ibool(i,k,ispec))*hprime_zz(j,k)
            b_dwz_dgamma = b_dwz_dgamma + b_displw_poroelastic(2,ibool(i,k,ispec))*hprime_zz(j,k)
          endif
          enddo

          xixl = xix(i,j,ispec)
          xizl = xiz(i,j,ispec)
          gammaxl = gammax(i,j,ispec)
          gammazl = gammaz(i,j,ispec)

! derivatives of displacement
          dux_dxl = dux_dxi*xixl + dux_dgamma*gammaxl
          dux_dzl = dux_dxi*xizl + dux_dgamma*gammazl

          duz_dxl = duz_dxi*xixl + duz_dgamma*gammaxl
          duz_dzl = duz_dxi*xizl + duz_dgamma*gammazl

          dwx_dxl = dwx_dxi*xixl + dwx_dgamma*gammaxl
          dwx_dzl = dwx_dxi*xizl + dwx_dgamma*gammazl

          dwz_dxl = dwz_dxi*xixl + dwz_dgamma*gammaxl
          dwz_dzl = dwz_dxi*xizl + dwz_dgamma*gammazl

          if(SIMULATION_TYPE == 3) then ! kernels calculation
          b_dux_dxl = b_dux_dxi*xixl + b_dux_dgamma*gammaxl
          b_dux_dzl = b_dux_dxi*xizl + b_dux_dgamma*gammazl

          b_duz_dxl = b_duz_dxi*xixl + b_duz_dgamma*gammaxl
          b_duz_dzl = b_duz_dxi*xizl + b_duz_dgamma*gammazl

          b_dwx_dxl = b_dwx_dxi*xixl + b_dwx_dgamma*gammaxl
          b_dwx_dzl = b_dwx_dxi*xizl + b_dwx_dgamma*gammazl

          b_dwz_dxl = b_dwz_dxi*xixl + b_dwz_dgamma*gammaxl
          b_dwz_dzl = b_dwz_dxi*xizl + b_dwz_dgamma*gammazl
          endif

! compute stress tensor (include attenuation if needed)

  if(ATTENUATION_VISCOELASTIC_SOLID) then
! Dissipation only controlled by frame share attenuation in poroelastic (see Morency & Tromp, GJI 2008).
! attenuation is implemented following the memory variable formulation of
! J. M. Carcione, Seismic modeling in viscoelastic media, Geophysics,
! vol. 58(1), p. 110-120 (1993). More details can be found in
! J. M. Carcione, D. Kosloff and R. Kosloff, Wave propagation simulation in a linear
! viscoelastic medium, Geophysical Journal International, vol. 95, p. 597-611 (1988).

! When implementing viscoelasticity according to Carcione 1993 paper, the attenuation is
! non-causal rather than causal. We fixed the problem by using equations in Carcione's
! 2004 paper and his 2007 book (Carcione 2007 page 125).

!J. M. Carcione, H B. Helle, The physics and simulation of wave propagation at the ocean
! bottom, Geophysics, vol. 69(3), p. 825-839, 2004
!J. M. Carcione, Wave fields in real media: wave propagation in anisotropic, anelastic
! and porous media, Elsevier, p. 124-125, 2007


! compute unrelaxed elastic coefficients from formulas in Carcione 2007 page 125
    lambdal_relaxed_viscoelastic = (lambdal_G + mul_G) - mul_G / Mu_nu2(i,j,ispec)
    mul_relaxed_viscoelastic = mul_G / Mu_nu2(i,j,ispec)
    lambdalplus2mul_relaxed_viscoel = lambdal_relaxed_viscoelastic + TWO*mul_relaxed_viscoelastic

! compute the stress using the unrelaxed Lame parameters (Carcione 2007 page 125)
    sigma_xx = (lambdal_G + 2.0 * mul_G)*dux_dxl + mul_G*duz_dzl + C_biot*(dwx_dxl + dwz_dzl)
    sigma_xz = mul_G*(duz_dxl + dux_dzl)
    sigma_zz = (lambdal_G + 2.0 * mul_G)*duz_dzl + mul_G*dux_dxl + C_biot*(dwx_dxl + dwz_dzl)

    sigmap = C_biot*(dux_dxl + duz_dzl) + M_biot*(dwx_dxl + dwz_dzl)

! add the memory variables using the relaxed parameters (Carcione 2007 page 125)
! beware: there is a bug in Carcione's equation (2c) of his 1993 paper for sigma_zz, we fixed it in the code below
    e11_sum = 0._CUSTOM_REAL
    e13_sum = 0._CUSTOM_REAL

    do i_sls = 1,N_SLS
      e11_sum = e11_sum + e11(i,j,ispec,i_sls)
      e13_sum = e13_sum + e13(i,j,ispec,i_sls)
    enddo

! mul_G is the relaxed modulus. Note that it is defined as the
! frame modulus (in compute_forces_poro_solid.f90), which Christina Morency noted
! mul_fr, which is in her case equivalent to the solid phase shear
! modulus, and whose value is entered in Par_file for example
    sigma_xx = sigma_xx + TWO * mul_relaxed_viscoelastic * e11_sum
    sigma_xz = sigma_xz + mul_relaxed_viscoelastic * e13_sum
    sigma_zz = sigma_zz - TWO * mul_relaxed_viscoelastic * e11_sum

  else

! no attenuation
    sigma_xx = lambdalplus2mul_G*dux_dxl + lambdal_G*duz_dzl + C_biot*(dwx_dxl + dwz_dzl)
    sigma_xz = mul_G*(duz_dxl + dux_dzl)
    sigma_zz = lambdalplus2mul_G*duz_dzl + lambdal_G*dux_dxl + C_biot*(dwx_dxl + dwz_dzl)

    sigmap = C_biot*(dux_dxl + duz_dzl) + M_biot*(dwx_dxl + dwz_dzl)

          if(SIMULATION_TYPE == 3) then ! kernels calculation
    b_sigma_xx = lambdalplus2mul_G*b_dux_dxl + lambdal_G*b_duz_dzl + C_biot*(b_dwx_dxl + b_dwz_dzl)
    b_sigma_xz = mul_G*(b_duz_dxl + b_dux_dzl)
    b_sigma_zz = lambdalplus2mul_G*b_duz_dzl + lambdal_G*b_dux_dxl + C_biot*(b_dwx_dxl + b_dwz_dzl)

    b_sigmap = C_biot*(b_dux_dxl + b_duz_dzl) + M_biot*(b_dwx_dxl + b_dwz_dzl)
          endif
  endif

! kernels calculation
   if(SIMULATION_TYPE == 3) then
          iglob = ibool(i,j,ispec)
            C_k(iglob) =  ((dux_dxl + duz_dzl) *  (b_dwx_dxl + b_dwz_dzl) + &
                  (dwx_dxl + dwz_dzl) *  (b_dux_dxl + b_duz_dzl)) * C_biot
            M_k(iglob) = (dwx_dxl + dwz_dzl) *  (b_dwx_dxl + b_dwz_dzl) * M_biot
   endif

          jacobianl = jacobian(i,j,ispec)

! weak formulation term based on stress tensor (symmetric form)
! also add GLL integration weights
          tempx1(i,j) = wzgll(j)*jacobianl*(sigma_xx*xixl+sigma_xz*xizl)
          tempz1(i,j) = wzgll(j)*jacobianl*(sigma_xz*xixl+sigma_zz*xizl)

          tempx2(i,j) = wxgll(i)*jacobianl*(sigma_xx*gammaxl+sigma_xz*gammazl)
          tempz2(i,j) = wxgll(i)*jacobianl*(sigma_xz*gammaxl+sigma_zz*gammazl)

          tempx1p(i,j) = wzgll(j)*jacobianl*sigmap*xixl
          tempz1p(i,j) = wzgll(j)*jacobianl*sigmap*xizl

          tempx2p(i,j) = wxgll(i)*jacobianl*sigmap*gammaxl
          tempz2p(i,j) = wxgll(i)*jacobianl*sigmap*gammazl

          if(SIMULATION_TYPE == 3) then ! kernels calculation
          b_tempx1(i,j) = wzgll(j)*jacobianl*(b_sigma_xx*xixl+b_sigma_xz*xizl)
          b_tempz1(i,j) = wzgll(j)*jacobianl*(b_sigma_xz*xixl+b_sigma_zz*xizl)

          b_tempx2(i,j) = wxgll(i)*jacobianl*(b_sigma_xx*gammaxl+b_sigma_xz*gammazl)
          b_tempz2(i,j) = wxgll(i)*jacobianl*(b_sigma_xz*gammaxl+b_sigma_zz*gammazl)

          b_tempx1p(i,j) = wzgll(j)*jacobianl*b_sigmap*xixl
          b_tempz1p(i,j) = wzgll(j)*jacobianl*b_sigmap*xizl

          b_tempx2p(i,j) = wxgll(i)*jacobianl*b_sigmap*gammaxl
          b_tempz2p(i,j) = wxgll(i)*jacobianl*b_sigmap*gammazl
          endif

        enddo
      enddo

!
! second double-loop over GLL to compute all the terms
!
      do j = 1,NGLLZ
        do i = 1,NGLLX

          iglob = ibool(i,j,ispec)

! along x direction and z direction
! and assemble the contributions
! we can merge the two loops because NGLLX == NGLLZ
          do k = 1,NGLLX

    accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) + ( (rhol_f/rhol_bar*tempx1(k,j) - tempx1p(k,j)) &
           *hprimewgll_xx(k,i) + (rhol_f/rhol_bar*tempx2(i,k) - tempx2p(i,k))*hprimewgll_zz(k,j) )

    accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) + ( (rhol_f/rhol_bar*tempz1(k,j) - tempz1p(k,j)) &
           *hprimewgll_xx(k,i) + (rhol_f/rhol_bar*tempz2(i,k) - tempz2p(i,k))*hprimewgll_zz(k,j) )

          if(SIMULATION_TYPE == 3) then ! kernels calculation
    b_accelw_poroelastic(1,iglob) = b_accelw_poroelastic(1,iglob) + ( (rhol_f/rhol_bar*b_tempx1(k,j) - b_tempx1p(k,j)) &
           *hprimewgll_xx(k,i) + (rhol_f/rhol_bar*b_tempx2(i,k) - b_tempx2p(i,k))*hprimewgll_zz(k,j) )

    b_accelw_poroelastic(2,iglob) = b_accelw_poroelastic(2,iglob) + ( (rhol_f/rhol_bar*b_tempz1(k,j) - b_tempz1p(k,j)) &
           *hprimewgll_xx(k,i) + (rhol_f/rhol_bar*b_tempz2(i,k) - b_tempz2p(i,k))*hprimewgll_zz(k,j) )
          endif

          enddo

        enddo ! second loop over the GLL points
      enddo

    endif ! end of test if poroelastic element

    enddo ! end of loop over all spectral elements

!
!---- viscous damping
!
! add - eta_f k^-1 dot(w)

! loop over spectral elements
  do ispec = 1,nspec

    etal_f = poroelastcoef(2,2,kmato(ispec))

    if(poroelastic(ispec) .and. etal_f > 0.d0) then

    permlxx = permeability(1,kmato(ispec))
    permlxz = permeability(2,kmato(ispec))
    permlzz = permeability(3,kmato(ispec))

! calcul of the inverse of k
    detk = permlxx*permlzz - permlxz*permlxz

    if(detk /= ZERO) then
     invpermlxx = permlzz/detk
     invpermlxz = -permlxz/detk
     invpermlzz = permlxx/detk
    else
      stop 'Permeability matrix is not invertible'
    endif

! relaxed viscous coef
          bl_unrelaxed_elastic(1) = etal_f*invpermlxx
          bl_unrelaxed_elastic(2) = etal_f*invpermlxz
          bl_unrelaxed_elastic(3) = etal_f*invpermlzz

    if(ATTENUATION_PORO_FLUID_PART) then
! viscous attenuation is implemented following the memory variable formulation of
! J. M. Carcione Wave fields in real media: wave propagation in anisotropic,
! anelastic and porous media, Elsevier, p. 304-305, 2007
          bl_relaxed_viscoelastic(1) = etal_f*invpermlxx*theta_e/theta_s
          bl_relaxed_viscoelastic(2) = etal_f*invpermlxz*theta_e/theta_s
          bl_relaxed_viscoelastic(3) = etal_f*invpermlzz*theta_e/theta_s
    endif

      do j = 1,NGLLZ
        do i = 1,NGLLX

          iglob = ibool(i,j,ispec)

     if(ATTENUATION_PORO_FLUID_PART) then
! compute the viscous damping term with the unrelaxed viscous coef and add memory variable
      viscodampx = velocw_poroelastic(1,iglob)*bl_relaxed_viscoelastic(1) + velocw_poroelastic(2,iglob)*bl_relaxed_viscoelastic(2)&
                 - rx_viscous(i,j,ispec)
      viscodampz = velocw_poroelastic(1,iglob)*bl_relaxed_viscoelastic(2) + velocw_poroelastic(2,iglob)*bl_relaxed_viscoelastic(3)&
                 - rz_viscous(i,j,ispec)
     else
! no viscous attenuation
      viscodampx = velocw_poroelastic(1,iglob)*bl_unrelaxed_elastic(1) + velocw_poroelastic(2,iglob)*bl_unrelaxed_elastic(2)
      viscodampz = velocw_poroelastic(1,iglob)*bl_unrelaxed_elastic(2) + velocw_poroelastic(2,iglob)*bl_unrelaxed_elastic(3)
     endif

            accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) - wxgll(i)*wzgll(j)*jacobian(i,j,ispec)*&
              viscodampx
            accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) - wxgll(i)*wzgll(j)*jacobian(i,j,ispec)*&
              viscodampz

          if(SIMULATION_TYPE == 1 .and. SAVE_FORWARD)  then
            b_viscodampx(iglob) = wxgll(i)*wzgll(j)*jacobian(i,j,ispec) * viscodampx
            b_viscodampz(iglob) = wxgll(i)*wzgll(j)*jacobian(i,j,ispec) * viscodampz
          else if(SIMULATION_TYPE == 3) then ! kernels calculation
            b_accelw_poroelastic(1,iglob) = b_accelw_poroelastic(1,iglob) - b_viscodampx(iglob)
            b_accelw_poroelastic(2,iglob) = b_accelw_poroelastic(2,iglob) - b_viscodampz(iglob)
          endif

        enddo
      enddo

    endif ! end of test if poroelastic element

    enddo ! end of loop over all spectral elements


!
!--- absorbing boundaries
!
  if(anyabs) then

    do ispecabs=1,nelemabs

      ispec = numabs(ispecabs)

   if (poroelastic(ispec)) then
! get poroelastic parameters of current spectral element
    phil = porosity(kmato(ispec))
    tortl = tortuosity(kmato(ispec))
    permlxx = permeability(1,kmato(ispec))
!solid properties
    mul_s = poroelastcoef(2,1,kmato(ispec))
    kappal_s = poroelastcoef(3,1,kmato(ispec)) - 4._CUSTOM_REAL*mul_s/3._CUSTOM_REAL
    rhol_s = density(1,kmato(ispec))
!fluid properties
    kappal_f = poroelastcoef(1,2,kmato(ispec))
    rhol_f = density(2,kmato(ispec))
    etal_f = poroelastcoef(2,2,kmato(ispec))
!frame properties
    mul_fr = poroelastcoef(2,3,kmato(ispec))
    kappal_fr = poroelastcoef(3,3,kmato(ispec)) - 4._CUSTOM_REAL*mul_fr/3._CUSTOM_REAL
    rhol_bar =  (1._CUSTOM_REAL - phil)*rhol_s + phil*rhol_f
!Biot coefficients for the input phi
      D_biot = kappal_s*(1._CUSTOM_REAL + phil*(kappal_s/kappal_f - 1._CUSTOM_REAL))
      H_biot = (kappal_s - kappal_fr)*(kappal_s - kappal_fr)/(D_biot - kappal_fr) + kappal_fr + 4._CUSTOM_REAL*mul_fr/3._CUSTOM_REAL
      C_biot = kappal_s*(kappal_s - kappal_fr)/(D_biot - kappal_fr)
      M_biot = kappal_s*kappal_s/(D_biot - kappal_fr)

    call get_poroelastic_velocities(cpIsquare,cpIIsquare,cssquare,H_biot,C_biot,M_biot,mul_fr,phil, &
             tortl,rhol_s,rhol_f,etal_f,permlxx,f0,freq0,Q0,w_c,ATTENUATION_PORO_FLUID_PART)

      cpIl = sqrt(cpIsquare)
      cpIIl = sqrt(cpIIsquare)
      csl = sqrt(cssquare)

!--- left absorbing boundary
      if(codeabs(IEDGE4,ispecabs)) then

        i = 1

        jbegin = ibegin_edge4_poro(ispecabs)
        jend = iend_edge4_poro(ispecabs)

        do j = jbegin,jend

          iglob = ibool(i,j,ispec)

          xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
          zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
          jacobian1D = sqrt(xgamma**2 + zgamma**2)
          nx = - zgamma / jacobian1D
          nz = + xgamma / jacobian1D

          weight = jacobian1D * wzgll(j)

          rho_vpI = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIl
          rho_vpII = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIIl
          rho_vs = rhol_f/rhol_bar*(rhol_bar-rhol_f*phil/tortl)*csl

          if(poroelastic(ispec)) then
            vx = velocs_poroelastic(1,iglob)
            vz = velocs_poroelastic(2,iglob)
            vxf = velocw_poroelastic(1,iglob)
            vzf = velocw_poroelastic(2,iglob)

            vn = nx*vx+nz*vz
            vnf = nx*vxf+nz*vzf

            tx = rho_vpII*vnf*nx - rho_vs*(vx-vn*nx)
            tz = rho_vpII*vnf*nz - rho_vs*(vz-vn*nz)

            accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) - tx*weight
            accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) - tz*weight

            if(SIMULATION_TYPE == 1 .and. SAVE_FORWARD) then
              b_absorb_poro_w_left(1,j,ib_left(ispecabs),it) = tx*weight
              b_absorb_poro_w_left(2,j,ib_left(ispecabs),it) = tz*weight
            else if(SIMULATION_TYPE == 3) then
              b_accelw_poroelastic(1,iglob) = b_accelw_poroelastic(1,iglob) - &
                                              b_absorb_poro_w_left(1,j,ib_left(ispecabs),NSTEP-it+1)
              b_accelw_poroelastic(2,iglob) = b_accelw_poroelastic(2,iglob) - &
                                              b_absorb_poro_w_left(2,j,ib_left(ispecabs),NSTEP-it+1)
            endif

          endif

        enddo

      endif  !  end of left absorbing boundary

!--- right absorbing boundary
      if(codeabs(IEDGE2,ispecabs)) then

        i = NGLLX

        jbegin = ibegin_edge2_poro(ispecabs)
        jend = iend_edge2_poro(ispecabs)

        do j = jbegin,jend

          iglob = ibool(i,j,ispec)

          xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
          zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
          jacobian1D = sqrt(xgamma**2 + zgamma**2)
          nx = + zgamma / jacobian1D
          nz = - xgamma / jacobian1D

          weight = jacobian1D * wzgll(j)


          rho_vpI = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIl
          rho_vpII = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIIl
          rho_vs = rhol_f/rhol_bar*(rhol_bar-rhol_f*phil/tortl)*csl

          if(poroelastic(ispec)) then
            vx = velocs_poroelastic(1,iglob)
            vz = velocs_poroelastic(2,iglob)
            vxf = velocw_poroelastic(1,iglob)
            vzf = velocw_poroelastic(2,iglob)

            vn = nx*vx+nz*vz
            vnf = nx*vxf+nz*vzf

            tx = rho_vpII*vnf*nx - rho_vs*(vx-vn*nx)
            tz = rho_vpII*vnf*nz - rho_vs*(vz-vn*nz)

            accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) - tx*weight
            accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) - tz*weight

            if(SIMULATION_TYPE == 1 .and. SAVE_FORWARD) then
              b_absorb_poro_w_right(1,j,ib_right(ispecabs),it) = tx*weight
              b_absorb_poro_w_right(2,j,ib_right(ispecabs),it) = tz*weight
            else if(SIMULATION_TYPE == 3) then
              b_accelw_poroelastic(1,iglob) = b_accelw_poroelastic(1,iglob) - &
                                              b_absorb_poro_w_right(1,j,ib_right(ispecabs),NSTEP-it+1)
              b_accelw_poroelastic(2,iglob) = b_accelw_poroelastic(2,iglob) - &
                                              b_absorb_poro_w_right(2,j,ib_right(ispecabs),NSTEP-it+1)
            endif

          endif

        enddo

      endif  !  end of right absorbing boundary

!--- bottom absorbing boundary
      if(codeabs(IEDGE1,ispecabs)) then

        j = 1

        ibegin = ibegin_edge1_poro(ispecabs)
        iend = iend_edge1_poro(ispecabs)

! exclude corners to make sure there is no contradiction on the normal
        if(codeabs(IEDGE4,ispecabs)) ibegin = 2
        if(codeabs(IEDGE2,ispecabs)) iend = NGLLX-1

        do i = ibegin,iend

          iglob = ibool(i,j,ispec)

          xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
          zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
          jacobian1D = sqrt(xxi**2 + zxi**2)
          nx = + zxi / jacobian1D
          nz = - xxi / jacobian1D

          weight = jacobian1D * wxgll(i)


          rho_vpI = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIl
          rho_vpII = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIIl
          rho_vs = rhol_f/rhol_bar*(rhol_bar-rhol_f*phil/tortl)*csl

          if(poroelastic(ispec)) then
            vx = velocs_poroelastic(1,iglob)
            vz = velocs_poroelastic(2,iglob)
            vxf = velocw_poroelastic(1,iglob)
            vzf = velocw_poroelastic(2,iglob)

            vn = nx*vx+nz*vz
            vnf = nx*vxf+nz*vzf

            tx = rho_vpII*vnf*nx - rho_vs*(vx-vn*nx)
            tz = rho_vpII*vnf*nz - rho_vs*(vz-vn*nz)

            accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) - tx*weight
            accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) - tz*weight

            if(SIMULATION_TYPE == 1 .and. SAVE_FORWARD) then
              b_absorb_poro_w_bottom(1,i,ib_bottom(ispecabs),it) = tx*weight
              b_absorb_poro_w_bottom(2,i,ib_bottom(ispecabs),it) = tz*weight
            else if(SIMULATION_TYPE == 3) then
              b_accelw_poroelastic(1,iglob) = b_accelw_poroelastic(1,iglob) - &
                                              b_absorb_poro_w_bottom(1,i,ib_bottom(ispecabs),NSTEP-it+1)
              b_accelw_poroelastic(2,iglob) = b_accelw_poroelastic(2,iglob) - &
                                              b_absorb_poro_w_bottom(2,i,ib_bottom(ispecabs),NSTEP-it+1)
            endif

          endif

        enddo

      endif  !  end of bottom absorbing boundary

!--- top absorbing boundary
      if(codeabs(IEDGE3,ispecabs)) then

        j = NGLLZ

        ibegin = ibegin_edge3_poro(ispecabs)
        iend = iend_edge3_poro(ispecabs)

! exclude corners to make sure there is no contradiction on the normal
        if(codeabs(IEDGE4,ispecabs)) ibegin = 2
        if(codeabs(IEDGE2,ispecabs)) iend = NGLLX-1

        do i = ibegin,iend

          iglob = ibool(i,j,ispec)

          xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
          zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
          jacobian1D = sqrt(xxi**2 + zxi**2)
          nx = - zxi / jacobian1D
          nz = + xxi / jacobian1D

          weight = jacobian1D * wxgll(i)


          rho_vpI = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIl
          rho_vpII = (rhol_f*tortl*rhol_bar - phil*rhol_f*rhol_f)/(phil*rhol_bar)*cpIIl
          rho_vs = rhol_f/rhol_bar*(rhol_bar-rhol_f*phil/tortl)*csl

          if(poroelastic(ispec)) then
            vx = velocs_poroelastic(1,iglob)
            vz = velocs_poroelastic(2,iglob)
            vxf = velocw_poroelastic(1,iglob)
            vzf = velocw_poroelastic(2,iglob)

            vn = nx*vx+nz*vz
            vnf = nx*vxf+nz*vzf

            tx = rho_vpII*vnf*nx - rho_vs*(vx-vn*nx)
            tz = rho_vpII*vnf*nz - rho_vs*(vz-vn*nz)

            accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) - tx*weight
            accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) - tz*weight

            if(SIMULATION_TYPE == 1 .and. SAVE_FORWARD) then
              b_absorb_poro_w_top(1,i,ib_top(ispecabs),it) = tx*weight
              b_absorb_poro_w_top(2,i,ib_top(ispecabs),it) = tz*weight
            else if(SIMULATION_TYPE == 3) then
              b_accelw_poroelastic(1,iglob) = b_accelw_poroelastic(1,iglob) - &
                                              b_absorb_poro_w_top(1,i,ib_top(ispecabs),NSTEP-it+1)
              b_accelw_poroelastic(2,iglob) = b_accelw_poroelastic(2,iglob) - &
                                              b_absorb_poro_w_top(2,i,ib_top(ispecabs),NSTEP-it+1)
            endif

          endif

        enddo

      endif  !  end of top absorbing boundary

    endif ! if poroelastic(ispec)
   enddo

  endif  ! end of absorbing boundaries


! --- add the source
  if(.not. initialfield) then
    do i_source=1,NSOURCES
! if this processor core carries the source and the source element is poroelastic
     if (is_proc_source(i_source) == 1 .and. poroelastic(ispec_selected_source(i_source))) then

    phil = porosity(kmato(ispec_selected_source(i_source)))
    rhol_s = density(1,kmato(ispec_selected_source(i_source)))
    rhol_f = density(2,kmato(ispec_selected_source(i_source)))
    rhol_bar = (1._CUSTOM_REAL - phil)*rhol_s + phil*rhol_f

! moment tensor
  if(source_type(i_source) == 2) then

! add source array
       if(SIMULATION_TYPE == 1) then  ! forward wavefield
      do j=1,NGLLZ
        do i=1,NGLLX
          iglob = ibool(i,j,ispec_selected_source(i_source))
          accelw_poroelastic(:,iglob) = accelw_poroelastic(:,iglob) + &
            (1._CUSTOM_REAL - rhol_f/rhol_bar)*sourcearray(i_source,:,i,j)*source_time_function(i_source,it,i_stage)
        enddo
      enddo
       else                   ! backward wavefield
      do j=1,NGLLZ
        do i=1,NGLLX
          iglob = ibool(i,j,ispec_selected_source(i_source))
          b_accelw_poroelastic(:,iglob) = b_accelw_poroelastic(:,iglob) + &
            (1._CUSTOM_REAL - rhol_f/rhol_bar)*sourcearray(i_source,:,i,j) * &
             source_time_function(i_source,NSTEP-it+1,stage_time_scheme-i_stage+1)
        enddo
      enddo
       endif  !endif SIMULATION_TYPE == 1

  endif !if(source_type(i_source) == 2)

     endif ! if this processor core carries the source and the source element is poroelastic
      enddo

    if(SIMULATION_TYPE == 3) then   ! adjoint wavefield
      irec_local = 0
      do irec = 1,nrec
!   add the source (only if this proc carries the source)
      if(myrank == which_proc_receiver(irec)) then

      irec_local = irec_local + 1
      if(poroelastic(ispec_selected_rec(irec))) then
    phil = porosity(kmato(ispec_selected_rec(irec)))
    rhol_s = density(1,kmato(ispec_selected_rec(irec)))
    rhol_f = density(2,kmato(ispec_selected_rec(irec)))
    rhol_bar = (1._CUSTOM_REAL - phil)*rhol_s + phil*rhol_f
! add source array
      do j=1,NGLLZ
        do i=1,NGLLX
          iglob = ibool(i,j,ispec_selected_rec(irec))
          accelw_poroelastic(1,iglob) = accelw_poroelastic(1,iglob) - &
               rhol_f/rhol_bar*adj_sourcearrays(irec_local,NSTEP-it+1,1,i,j)
          accelw_poroelastic(2,iglob) = accelw_poroelastic(2,iglob) - &
               rhol_f/rhol_bar*adj_sourcearrays(irec_local,NSTEP-it+1,3,i,j)
       enddo
      enddo
      endif ! if element is poroelastic

      endif ! if this processor core carries the adjoint source and the source element is poroelastic
      enddo ! irec = 1,nrec
    endif ! SIMULATION_TYPE == 3 adjoint wavefield

  endif ! if not using an initial field

  end subroutine compute_forces_poro_fluid

