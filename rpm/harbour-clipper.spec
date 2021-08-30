# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-clipper

# >> macros
%define __provides_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so\\>
%define __requires_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so\\>
# << macros

Summary:    Videoworks
Version:    0.3.6
Release:    1
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/poetater/harbour-clipper
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   ffmpeg-tools
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  desktop-file-utils

%description
Videoworks is a video editing application. In beta.


%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_libdir}/frei0r-1
# >> files
# << files
