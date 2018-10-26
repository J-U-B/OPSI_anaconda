# ![](./SRC/IMAGES/AnacondaLogo.png "Anaconda")   Anaconda 2/3 #

## ToC ##

* [Paketinfo](#paketinfo)
  * [Was ist Anaconda?](#anaconda-info)
* [Paket erstellen](#paket_erstellen)
  * [Makefile und spec.json](#makefile_und_spec)
  * [pystache](#pystache)
  * [Verzeichnisstruktur](#verzeichnisstruktur)
  * [Makefile-Parameter](#makefile_parameter)
  * [spec.json](#spec_json)
    * [32-Bit-Umgebung](#spec_32bit)
* [Installation](#installation)
  * [Properties](#properties)
* [Allgemeines](#allgemeines)
  * [Aufbau des Paketes](#paketaufbau)
  * [Nomenklatur](#nomenklatur)
  * [Unattended-Switches](#unattended_switches)
* [Lizenzen](#lizenzen)
  * [Dieses Paket](#lic_paket)
  * [Anaconda](#lic_anaconda)
  * [psDetail](#lic_psdetail)
* [Anmerkungen/ToDo](#anmerkungen_todo)


<div id="paketinfo"></div>

Diese OPSI-Paket fuer **Anaconda 2/3** wurde fuer die Verwendung im *OPSI-4-Institutes*-Repository
sowie des *Max-Planck-Instituts fuer Mikrostrukturphysik* erstellt.  
Es wird versucht auf die Besonderheiten der jeweiligen Repositories einzugehen;
entsprechend werden durch ein einfaches *Makefile* aus den Quellen verschiedene
Pakete erstellt.  
Grundsaetzlich werden <u>separate OPSI-Pakete</u> für **Anaconda2** und **Anaconda3**
erstellt.

<div id="anaconda-info"></div>

###Was ist Anaconda?###

Anaconda ist eine Freemium-Open-Source-Distribution für die Programmiersprachen 
**Python** und **R**, die unter anderem die Entwicklungsumgebung **Spyder**, 
den Kommandozeileninterpreter **IPython**, und ein webbasiertes Frontend für 
**Jupyter** enthält.  
Der Fokus liegt vor allem auf der Verarbeitung von großen Datenmengen, Vorhersageanalyse 
und wissenschaftlichem Rechnen.  
Das Ziel der Distribution ist die Vereinfachung
von Paketmanagement und Softwareverteilung.  
*([Wikipedia](https://de.wikipedia.org/wiki/Anaconda_(Python-Distribution))*


<div id="paket_erstellen"></div>

## Paket erstellen ##

Dieser Abschnitt beschaeftigt sich mit der Erstellung des OPSI-Paketes aus
dem Source-Paket und nicht mit dem OPSI-Paket selbst.


<div id="makefile_und_spec"></div>

### Makefile und spec.json ###

Da aus den Quellen verschiedene Versionen des Paketes mit entsprechenden Anpassungen
generiert werden sollen (intern, DFN; testing/release) wurde hierfuer ein
**<code>Makefile</code>** erstellt. Darueber hinaus steuert **<code>spec.json</code>** 
die Erstellung der Pakete.  

Im Idealfall ist beim Erscheinen einer neuen Release von Anaconda lediglich die
**<code>spec.json</code>** anzupassen.

Zur Vorbereitung der eigentlichen Paketerstellung sind zuvor die Softwarepakete
mit
><code>make download</code>

herunterzuladen. Hierbei werden die spaeter benoetigten MD5sums erstellt.


<div id="pystache"></div>

### pystache ###

Als Template-Engine kommt **<code>pystache</code>** zum Einsatz.
Das entsprechende Paket ist auf dem Build-System aus dem Repository der verwendeten
Distribution zu installieren.

Unter Debian/Ubuntu erledigt das:
> <code>sudo apt-get install python-pystache</code>


<div id="verzeichnisstruktur"></div>

### Verzeichnisstruktur ###

Die erstellten Pakete werden im Unterverzeichnis **<code>BUILD</code>** abgelegt.

Einige Files (derzeit <code>control, preinst, postinst</code>) werden bei der Erstellung erst aus _<code>.in</code>_-Files
generiert, welche sich in den Verzeichnissen <code>SRC/OPSI</code> und <code>SRC/CLIENT_DATA</code> befinden.
Die <code>SRC</code>-Verzeichnisse sind in den OPSI-Paketen nicht mehr enthalten.


<div id="makefile_parameter"></div>

### Makefile-Parameter ###
Eine kurze Hilfe zu den verfuegbaren Parametern liefert:
><code>make help</code>

Der vorliegende Code erlaubt die Erstellung von OPSI-Paketen fuer die Releases
gemaess der Angaben in <code>spec.json</code>. Es kann jedoch bei der Paketerstellung
ein alternatives Spec--File uebergeben werden:

> *<code>SPEC=&lt;spec_file&gt;</code>*


Aus den vorliegenden Skripten koennen OPSI-Pakete fuer Anaconda2 und/oder Anaconda3
erstellt werden:

> *<code>PYVER=&lt;2|3|2,3|both&gt;</code>*

Das Paket kann mit *"batteries included"* erstellt werden. In dem Fall erfolgt 
der Download der Software beim Erstellen des OPSI-Paketes und nicht erst bei
dessen Installation:
> *<code>ALLINC=[true|false]</code>*

Standard ist hier die Erstellung des leichtgewichtigen Paketes (```ALLINC=false```).

OPSI erlaubt des Pakete im Format <code>cpio</code> und <code>tar</code> zu erstellen.  
Als Standard ist <code>cpio</code> festgelegt.  
Das Makefile erlaubt die Wahl des Formates ueber die Umgebungsvariable bzw. den Parameter:
> *<code>ARCHIVE_FORMAT=&lt;cpio|tar&gt;</code>*


<div id="spec_json"></div>

### spec.json ###

Haeufig beschraenkt sich die Aktualisierung eines Paketes auf das Aendern der 
Versionsnummern und des Datums etc. In einigen Faellen ist jedoch auch das Anpassen
weiterer Variablen erforderlich, die sich auf verschiedene Files verteilen.  
Auch das soll durch das Makefile vereinfacht werden. Die relevanten Variablen
sollen nur noch in <code>spec.json</code> angepasst werden. Den Rest uebernimmt *<code>make</code>*

<div id="spec_32bit"></div>

#### 32-Bit-Umgebung####

Die 32-Bit-Systeme kommen immer seltener zum Einsatz. Daher ist es nicht in
jedem Fall erforderlich auch eine entsprechende Version von Anacoda zur Verfuegung
zu stellen. Beeinflussen laesst sich das ueber das spec-File mit:
>*<code>"ifdef_64bit_only" :true</code>*

Standardmaessig ist der Support fuer 32 Bit aktiviert..


<div id="installation"></div>

## Installation ##

Die Software selbst wird - sofern bei der Paketerstellung nicht anders vorgegeben - 
<u>nicht</u> mit diesem Paket vertrieben. Fuer die *"batteries included"*-Pakete 
entfaellt dieser Abschnitt.

Je nach Art des erstellten Paketes erfolgt bei der Installation im Depot durch 
das <code>postinst</code>-Script der Download der Software vom Hersteller 
(moeglich sind hier Umgebungen für Python 2 und Python 3, jeweils 32 und 64 Bit).  
Ein manueller Download sollte dann nicht erforderlich sein. 
Auf dem Depot-Server ist **wget** erforderlich.

Das Gesamtvolumen der herunterzuladenden Dateien betraegt in der umfangreichsten
Konfiguration ca. **1920 MByte** (Anaconada 2 und 3, 32/64 Bit)!


<div id="properties"></div>

## Properties ##

Zur Steuerung der Installation des Paketes auf den Clients ist eine Reihe von 
Properties vorgesehen. Einige hiervon sind eher generischer Natur, andere spezifisch 
fuer die vorliegende Software.

### generische Properties ###

**<code>kill_running</code>** - Wird bei der Installation eine laufende Instanz
definierter Programme  erkannt (<code>python.exe, pythonw.exe, Scripts\*.exe</code>
im Zielverzeichnis), koennen diese durch das OPSI-Paket beendet werden.  
Sollen ggf. laufende Programme nicht beendet werden, wird die Installation
des Paketes zurueckgestellt und spaeter erneut versucht.  
(*default: false*)

**<code>install_architecture</code>** - Diese Option ist nur verfuegbar, wenn
das Paket nicht ausschliesslich fuer 64-Bit-Umgebungen erstellt wurde (siehe 
[32-Bit-Umgebung](#spec_32bit)) und legt fest, welche Architektur der Software
installiert werden soll.  
Zur Auswahl stehen: "32 bit", "64 bit", "sysnative".
(*default: sysnative*)

**<code>log_level</code>** - Es kann hier ein abweichender Log-Level fuer das
Paket definiert werden. Fuer Test-Pakete ist der Default-Wert 7, fuer Produktiv-Pakete
wurde 5 festgelegt.

**<code>custom_post_install</code>** und **<code>custom_post_uninstall</code>** - Hier
koennen Skripte hinterlegt werden, welche optional nach Abschluss der Installation
bzw. Deinstallation ausgefuehrt werden sollen. Die Skripte muessen im Unterverzeichnis
<code>custom</code> des Paketes auf dem Depot-Server liegen.
(*default: none*)

**<code>required_mimimum_space</code>** - Aufgrund der Komplexitaet des vorliegenden
Paketes und der daraus entstehenden Setups laesst sich der erforderliche Platzbedarf
auf dem Zielsystem nicht im Voraus exakt bestimmen. Mit dieser Variablen laesst
sich die Angabe praezisieren.  
Der Default-Wert betraegt 9000 (Megabyte). Es koennen hier neben absoluten
auch relative Werte angegeben werden. Hierfuer der Wert mit einem Vorzeichen (+/-)
zu versehen.  
Bei Installation zusaetzlicher Pakete (<code>additional_packages</code>) ist
der Wert ggf. zu erhoehen.  
Es ist zu beruecksichtigen, dass fuer die Bemessung des Wertes nicht der Umfang
des Setups nach der Installation relevant ist, sondern der Maximal-Bedarf
waehrend der Installation. Dieser Wert kann deutlich hoeher ausfallen.


### spezifische Properties ###

**<code>additional_packages</code>** - Neben der Distribution koennen bei der
Installation gleich weitere Pakete hinzugefuegt werden (z.B. <code>tensorflow</code>, 
<code>django</code>, ...). Werden hier mehrere Pakete angegeben, erfolgt die 
Trennung ueber Leerzeichen.  
Gegebenenfalls ist eine Anpassung von <code>required_mimimum_space</code>
erforderlich.  
Fuer diese Funktion ist eine Verbindung zum Internet erforderlich.  

**<code>additional_packages_install_mode</code>** - Fuer die unter <code>additional_packages</code>
angegebenen Pakete laesst sich festlegen, wann die Installation erfolgen soll:
waehrend des Setup-Skriptes, des Update-Skriptes ...oder gar nicht. (*default: setup*)

**<code>upgrade_release</code>** - Das Update-Skript bietet die Moeglichkeit
fuer die Anaconda-Distribution inline ein Release-Upgrade vorzunehmen. Das erspart
unter Umstaenden die Notwendigkeit einer kompletten Neuinstallation bzw. ermoeglicht
ein Distributions-Upgrade ohne Vorliegen einer neuen Version des OPSI-Paketes.  
Hierbei werden jedoch die Versionsnummern in der Software-Verwaltung von Windows
und auf dem Depot-Server aktualisiert. Das erfolgte Upgrade laesst sich hier
nur anhand der Logs auf dem Depot-Server erkennen bzw. auf dem Client direkt
(z.B. mit <code>conda list</code>). - Experimentell!  
Fuer diese Funktion ist eine Verbindung zum Internet erforderlich.  
(*default: false*)

**<code>update_dry_run</code>** - Mit dieser Einstellung laesst sich den Logs
auf dem Depot-Server entnehmen, was bei einer Installation zusaeztlicher Pakete 
bzw. einem Upgrade/Update installiert werden <u>wuerde</u>.  
(*default: false*)

**<code>update_verbose</code>** - Hiermit liefert <code>conda</code> detailiertere Informationen.  
(*default: false*)

**<code>update_skip</code>** - Standardmaessig fuehrt OPSI bei Vorliegen eines
Update-Skriptes dieses im Anschluss an die Installation aus. Hiermit laesst sich
die Ausfuehrung unterbinden.  
Unabhaengig von der hier vorgenommenen Einstellung wird der Action-Request *Update*
jedoch ausgefuehrt.  
Fuer die Installation von Updates ist eine Verbindung zum Internet erforderlich.  
(*default: false*)

**<code>update_rights_skip</code>** - Bei der Installation von zusaetzlichen 
Paketen bzw. Updates kann es dazu kommen, dass Berechtigungen fuer Dateien
falsch gesetzt werden. Diese Einstellung erlaubt das Ueberspringen
der Reparatur von Zugriffsrechten waehrend des Updates um Zeit zu sparen. - Nicht empfohlen!  
(*default: false*)




**<code>link_desktop_Anaconda_Navigator</code>**,  
**<code>link_desktop_Spyder</code>**,  
**<code>link_desktop_Jupyter_Notebook</code>**,  
**<code>link_desktop_Anaconda_Prompt</code>** - optional kann fuer die angegebenen
Programme jeweils eine Verknuepung auf dem Desktop angelegt werden. (*default: false*)


<div id="allgemeines"></div>

## Allgemeines ##

<div id="aufbau_des_paketes"></div>

### Aufbau des Paketes ###
* **<code>variables.opsiinc</code>** - Da Variablen ueber die Scripte hinweg mehrfach
verwendet werden, werden diese (bis auf wenige Ausnahmen) zusammengefasst hier deklariert.
* **<code>product_variables.opsiinc</code>** - die producktspezifischen Variablen werden
hier definiert
* **<code>setup.opsiscript </code>** - Das Script fuer die Installation.
* **<code>update.opsiscript </code>** - Das Script fuer das Update bzw. Upgrade von Anaconda.
* **<code>uninstall.opsiscript</code>** - Das Uninstall-Script
* **<code>delsub.opsiinc</code>**- Wird von Setup und Uninstall gemeinsam verwendet.
Vor jeder Installation/jedem Update wird eine alte Version entfernt. (Ein explizites
Update-Script existiert derzeit nicht.)
* **<code>checkinstance.opsiinc</code>** - Pruefung, ob eine Instanz der Software laeuft.
Gegebenenfalls wird das Setup abgebrochen. Optional kann eine laufende Instanz 
zwangsweise beendet werden.
* **<code>checkvars.sh</code>** - Hilfsscript fuer die Entwicklung zur Ueberpruefung,
ob alle verwendeten Variablen deklariert sind bzw. nicht verwendete Variablen
aufzuspueren.
* **<code>bin/</code>** - Hilfprogramme; hier: **7zip**, **psdetail**
* **<code>images/</code>** - Programmbilder fuer OPSI

<div id="nomenklatur"></div>

### Nomenklatur ###
Praefixes in der Produkt-Id definieren die Art des Paketes:

* **0_** - Es handelt sich um ein Test-Paket. Beim Uebergang zur Produktions-Release
wird der Praefix entfernt.
* **dfn_** - Das Paket ist zur Verwendung im DFN-Repository vorgesehen.

Die Reihenfolge der Praefixes ist relevant; die Markierung als Testpaket ist 
stets fuehrend.

<div id="unattended_switches"></div>

### Unattended-Switches ###
Es handelt sich um ein *NSIS*-Paket mit den hier gebraeuchlichen Parametern.

siehe auch: http://www.silentinstall.org/nsis


<div id="lizenzen"></div>

## Lizenzen ##

<div id="lic_paket"></div>

###  Dieses Paket ###

Dieses OPSI-Paket steht unter der *GNU General Public License* **GPLv3**.

Ausgenommen von dieser Lizenz sind die unter **<code>bin/</code>** zu findenden
Hilfsprogramme. Diese unterliegen ihren jeweiligen Lizenzen.

<div id="lic_anaconda"></div>

### Anaconda ###
Anaconda steht unter **BSD-Lizenz**:

>Anaconda End User License Agreement
>===================================
>
>Copyright 2015, Anaconda, Inc.
>
>All rights reserved under the 3-clause BSD License:
>
>Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
>
>  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
>  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
>  * Neither the name of Anaconda, Inc. ("Anaconda, Inc.") nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
>
>THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ANACONDA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
>
>Notice of Third Party Software Licenses
>=======================================
>
>Anaconda Distribution contains open source software packages from third parties. These are available on an "as is" basis and subject to their individual license agreements. These licenses are available in Anaconda Distribution or at http://docs.anaconda.com/anaconda/pkg-docs. Any binary packages of these third party tools you obtain via Anaconda Distribution are subject to their individual licenses as well as the Anaconda license. Anaconda, Inc. reserves the right to change which third party tools are provided in Anaconda Distribution.
>
>In particular, Anaconda Distribution contains re-distributable, run-time, shared-library files from the Intel(TM) Math Kernel Library ("MKL binaries"). You are specifically authorized to use the MKL binaries with your installation of Anaconda Distribution. You are also authorized to redistribute the MKL binaries with Anaconda Distribution or in the conda package that contains them. Use and redistribution of the MKL binaries are subject to the licensing terms located at https://software.intel.com/en-us/license/intel-simplified-software-license. If needed, instructions for removing the MKL binaries after installation of Anaconda Distribution are available at http://www.anaconda.com.
>
>Anaconda Distribution also contains cuDNN software binaries from NVIDIA Corporation ("cuDNN binaries"). You are specifically authorized to use the cuDNN binaries with your installation of Anaconda Distribution. You are also authorized to redistribute the cuDNN binaries with an Anaconda Distribution package that contains them. If needed, instructions for removing the cuDNN binaries after installation of Anaconda Distribution are available at http://www.anaconda.com.
>
>
>Anaconda Distribution also contains Visual Studio Code software binaries from Microsoft Corporation ("VS Code"). You are specifically authorized to use VS Code with your installation of Anaconda Distribution. Use of VS Code is subject to the licensing terms located at https://code.visualstudio.com/License.
>
>Cryptography Notice
>===================
>
>This distribution includes cryptographic software. The country in which you currently reside may have restrictions on the import, possession, use, and/or re-export to another country, of encryption software. BEFORE using any encryption software, please check your country's laws, regulations and policies concerning the import, possession, or use, and re-export of encryption software, to see if this is permitted. See the Wassenaar Arrangement http://www.wassenaar.org/ for more information.
>
>Anaconda, Inc. has self-classified this software as Export Commodity Control Number (ECCN) 5D992b, which includes mass market information security software using or performing cryptographic functions with asymmetric algorithms. No license is required for export of this software to non-embargoed countries. In addition, the Intel(TM) Math Kernel Library contained in Anaconda, Inc.'s software is classified by Intel(TM) as ECCN 5D992b with no license required for export to non-embargoed countries.
>
>The following packages are included in this distribution that relate to cryptography:
>
>openssl
>    The OpenSSL Project is a collaborative effort to develop a robust, commercial-grade, full-featured, and Open Source toolkit implementing the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols as well as a full-strength general purpose cryptography library.
>
>pycrypto
>    A collection of both secure hash functions (such as SHA256 and RIPEMD160), and various encryption algorithms (AES, DES, RSA, ElGamal, etc.).
>
>pyopenssl
>    A thin Python wrapper around (a subset of) the OpenSSL library.
>
>kerberos (krb5, non-Windows platforms)
>    A network authentication protocol designed to provide strong authentication for client/server applications by using secret-key cryptography.
>
>cryptography
>    A Python library which exposes cryptographic recipes and primitives.


<div id="lic_psdetail"></div>

### psdetail ###
**Autor** der Software: Jens Boettge <<boettge@mpi-halle.mpg.de>> 

Die Software **psdetail.exe**  wird als Freeware kostenlos angeboten und darf fuer 
nichtkommerzielle sowie kommerzielle Zwecke genutzt werden. Die Software
darf nicht veraendert werden; es duerfen keine abgeleiteten Versionen daraus 
erstellt werden.

Es ist erlaubt Kopien der Software herzustellen und weiterzugeben, solange 
Vervielfaeltigung und Weitergabe nicht auf Gewinnerwirtschaftung oder Spendensammlung
abzielt.

Haftungsausschluss:  
Der Auto lehnt ausdruecklich jede Haftung fuer eventuell durch die Nutzung 
der Software entstandene Schaeden ab.  
Es werden keine ex- oder impliziten Zusagen gemacht oder Garantien bezueglich
der Eigenschaften, des Funktionsumfanges oder Fehlerfreiheit gegeben.  
Alle Risiken des Softwareeinsatzes liegen beim Nutzer.

Der Autor behaelt sich eine Anpassung bzw. weitere Ausformulierung der Lizenzbedingungen
vor.

Fuer die Nutzung wird das *.NET Framework ab v3.5*  benoetigt.


<div id="anmerkungen_todo"></div>

## Anmerkungen/ToDo ##

### Unterschiede zwischen Neuinstallation (5.3.0) und Upgrade (5.2.0 -> 5.3.0)

Mit *<code>upgrade_release</code>* laesst sich eine bestehende Installation
inline via <code>conda</code> upgraden. Dabei sind kleinere Abweichungen zu 
einer vollstaendigen Installation der neueren Distribution zu beobachten.

* Nach der Neuinstallation ist das Paket <code>bokeh</code> in Version 1.0.0
vorhanden, waehrend es nach einem Upgrade in Version 0.13.0 vorliegt. Das
kann jedoch ueber *<code>additional_packages</code>* ausgeglichen werden.
* Bei einer Neuinstallation fehlen die Pakete <code>conda-verify</code>,
<code>future</code> und <code>typing</code>, die nach einem Upgrade von 5.2
(noch) vorhanden sind.

-----
Jens Boettge <<boettge@mpi-halle.mpg.de>>, 2018-10-25 09:13:01 +0200
