;;; -*-Scheme-*-
;;;
;;; $Id: key-x11.scm,v 1.6 2002/11/20 19:46:00 cph Exp $
;;;
;;; Copyright (c) 1991-1999 Massachusetts Institute of Technology
;;;
;;; This file is part of MIT Scheme.
;;;
;;; MIT Scheme is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published
;;; by the Free Software Foundation; either version 2 of the License,
;;; or (at your option) any later version.
;;;
;;; MIT Scheme is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with MIT Scheme; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;;; 02111-1307, USA.
;;;

;;;; Keys
;;; Package: (edwin x-keys)

(declare (usual-integrations))

(define (x-make-special-key keysym bucky-bits)
  (make-special-key (or (keysym->name keysym)
			(editor-error "Keysym not registered:" keysym))
		    bucky-bits))

(define (keysym->name keysym)
  (let ((entry
	 (vector-binary-search x-key-translation-table
			       (lambda (u v) (< u v))
			       (lambda (pair) (car pair))
			       keysym)))
    (and entry (cdr entry))))

;; This table is a simple translation of /usr/include/X11/keysym.h.
;; However, that the vendor-specific marker (bit 28, numbered from 0)
;; has been moved to bit 23 so that all keysym values will fit in
;; Scheme fixnums, even with eight-bit type tags.  Duplicate keysyms
;; have been pruned arbitrarily.

(define x-key-translation-table
  (vector
   '(#x7B . braceleft)
   '(#x7C . bar)
   '(#x7D . braceright)
   '(#x7E . asciitilde)
   '(#xA0 . nobreakspace)
   '(#xA1 . exclamdown)
   '(#xA2 . cent)
   '(#xA3 . sterling)
   '(#xA4 . currency)
   '(#xA5 . yen)
   '(#xA6 . brokenbar)
   '(#xA7 . section)
   '(#xA8 . diaeresis)
   '(#xA9 . copyright)
   '(#xAA . ordfeminine)
   '(#xAB . guillemotleft)
   '(#xAC . notsign)
   '(#xAD . hyphen)
   '(#xAE . registered)
   '(#xAF . macron)
   '(#xB0 . degree)
   '(#xB1 . plusminus)
   '(#xB2 . twosuperior)
   '(#xB3 . threesuperior)
   '(#xB4 . acute)
   '(#xB5 . mu)
   '(#xB6 . paragraph)
   '(#xB7 . periodcentered)
   '(#xB8 . cedilla)
   '(#xB9 . onesuperior)
   '(#xBA . masculine)
   '(#xBB . guillemotright)
   '(#xBC . onequarter)
   '(#xBD . onehalf)
   '(#xBE . threequarters)
   '(#xBF . questiondown)
   '(#xC0 . Agrave)
   '(#xC1 . Aacute)
   '(#xC2 . Acircumflex)
   '(#xC3 . Atilde)
   '(#xC4 . Adiaeresis)
   '(#xC5 . Aring)
   '(#xC6 . AE)
   '(#xC7 . Ccedilla)
   '(#xC8 . Egrave)
   '(#xC9 . Eacute)
   '(#xCA . Ecircumflex)
   '(#xCB . Ediaeresis)
   '(#xCC . Igrave)
   '(#xCD . Iacute)
   '(#xCE . Icircumflex)
   '(#xCF . Idiaeresis)
   '(#xD0 . Eth)
   '(#xD1 . Ntilde)
   '(#xD2 . Ograve)
   '(#xD3 . Oacute)
   '(#xD4 . Ocircumflex)
   '(#xD5 . Otilde)
   '(#xD6 . Odiaeresis)
   '(#xD7 . multiply)
   '(#xD8 . Ooblique)
   '(#xD9 . Ugrave)
   '(#xDA . Uacute)
   '(#xDB . Ucircumflex)
   '(#xDC . Udiaeresis)
   '(#xDD . Yacute)
   '(#xDE . Thorn)
   '(#xDF . ssharp)
   '(#xE0 . agrave)
   '(#xE1 . aacute)
   '(#xE2 . acircumflex)
   '(#xE3 . atilde)
   '(#xE4 . adiaeresis)
   '(#xE5 . aring)
   '(#xE6 . ae)
   '(#xE7 . ccedilla)
   '(#xE8 . egrave)
   '(#xE9 . eacute)
   '(#xEA . ecircumflex)
   '(#xEB . ediaeresis)
   '(#xEC . igrave)
   '(#xED . iacute)
   '(#xEE . icircumflex)
   '(#xEF . idiaeresis)
   '(#xF0 . eth)
   '(#xF1 . ntilde)
   '(#xF2 . ograve)
   '(#xF3 . oacute)
   '(#xF4 . ocircumflex)
   '(#xF5 . otilde)
   '(#xF6 . odiaeresis)
   '(#xF7 . division)
   '(#xF8 . oslash)
   '(#xF9 . ugrave)
   '(#xFA . uacute)
   '(#xFB . ucircumflex)
   '(#xFC . udiaeresis)
   '(#xFD . yacute)
   '(#xFE . thorn)
   '(#xFF . ydiaeresis)
   '(#x1A1 . Aogonek)
   '(#x1A2 . breve)
   '(#x1A3 . Lstroke)
   '(#x1A5 . Lcaron)
   '(#x1A6 . Sacute)
   '(#x1A9 . Scaron)
   '(#x1AA . Scedilla)
   '(#x1AB . Tcaron)
   '(#x1AC . Zacute)
   '(#x1AE . Zcaron)
   '(#x1AF . Zabovedot)
   '(#x1B1 . aogonek)
   '(#x1B2 . ogonek)
   '(#x1B3 . lstroke)
   '(#x1B5 . lcaron)
   '(#x1B6 . sacute)
   '(#x1B7 . caron)
   '(#x1B9 . scaron)
   '(#x1BA . scedilla)
   '(#x1BB . tcaron)
   '(#x1BC . zacute)
   '(#x1BD . doubleacute)
   '(#x1BE . zcaron)
   '(#x1BF . zabovedot)
   '(#x1C0 . Racute)
   '(#x1C3 . Abreve)
   '(#x1C5 . Lacute)
   '(#x1C6 . Cacute)
   '(#x1C8 . Ccaron)
   '(#x1CA . Eogonek)
   '(#x1CC . Ecaron)
   '(#x1CF . Dcaron)
   '(#x1D0 . Dstroke)
   '(#x1D1 . Nacute)
   '(#x1D2 . Ncaron)
   '(#x1D5 . Odoubleacute)
   '(#x1D8 . Rcaron)
   '(#x1D9 . Uring)
   '(#x1DB . Udoubleacute)
   '(#x1DE . Tcedilla)
   '(#x1E0 . racute)
   '(#x1E3 . abreve)
   '(#x1E5 . lacute)
   '(#x1E6 . cacute)
   '(#x1E8 . ccaron)
   '(#x1EA . eogonek)
   '(#x1EC . ecaron)
   '(#x1EF . dcaron)
   '(#x1F0 . dstroke)
   '(#x1F1 . nacute)
   '(#x1F2 . ncaron)
   '(#x1F5 . odoubleacute)
   '(#x1F8 . rcaron)
   '(#x1F9 . uring)
   '(#x1FB . udoubleacute)
   '(#x1FE . tcedilla)
   '(#x1FF . abovedot)
   '(#x2A1 . Hstroke)
   '(#x2A6 . Hcircumflex)
   '(#x2A9 . Iabovedot)
   '(#x2AB . Gbreve)
   '(#x2AC . Jcircumflex)
   '(#x2B1 . hstroke)
   '(#x2B6 . hcircumflex)
   '(#x2B9 . idotless)
   '(#x2BB . gbreve)
   '(#x2BC . jcircumflex)
   '(#x2C5 . Cabovedot)
   '(#x2C6 . Ccircumflex)
   '(#x2D5 . Gabovedot)
   '(#x2D8 . Gcircumflex)
   '(#x2DD . Ubreve)
   '(#x2DE . Scircumflex)
   '(#x2E5 . cabovedot)
   '(#x2E6 . ccircumflex)
   '(#x2F5 . gabovedot)
   '(#x2F8 . gcircumflex)
   '(#x2FD . ubreve)
   '(#x2FE . scircumflex)
   '(#x3A2 . kappa)
   '(#x3A3 . Rcedilla)
   '(#x3A5 . Itilde)
   '(#x3A6 . Lcedilla)
   '(#x3AA . Emacron)
   '(#x3AB . Gcedilla)
   '(#x3AC . Tslash)
   '(#x3B3 . rcedilla)
   '(#x3B5 . itilde)
   '(#x3B6 . lcedilla)
   '(#x3BA . emacron)
   '(#x3BB . gcedilla)
   '(#x3BC . tslash)
   '(#x3BD . ENG)
   '(#x3BF . eng)
   '(#x3C0 . Amacron)
   '(#x3C7 . Iogonek)
   '(#x3CC . Eabovedot)
   '(#x3CF . Imacron)
   '(#x3D1 . Ncedilla)
   '(#x3D2 . Omacron)
   '(#x3D3 . Kcedilla)
   '(#x3D9 . Uogonek)
   '(#x3DD . Utilde)
   '(#x3DE . Umacron)
   '(#x3E0 . amacron)
   '(#x3E7 . iogonek)
   '(#x3EC . eabovedot)
   '(#x3EF . imacron)
   '(#x3F1 . ncedilla)
   '(#x3F2 . omacron)
   '(#x3F3 . kcedilla)
   '(#x3F9 . uogonek)
   '(#x3FD . utilde)
   '(#x3FE . umacron)
   '(#x47E . overline)
   '(#x4A1 . kana-fullstop)
   '(#x4A2 . kana-openingbracket)
   '(#x4A3 . kana-closingbracket)
   '(#x4A4 . kana-comma)
   '(#x4A5 . kana-conjunctive)
   '(#x4A6 . kana-WO)
   '(#x4A7 . kana-a)
   '(#x4A8 . kana-i)
   '(#x4A9 . kana-u)
   '(#x4AA . kana-e)
   '(#x4AB . kana-o)
   '(#x4AC . kana-ya)
   '(#x4AD . kana-yu)
   '(#x4AE . kana-yo)
   '(#x4AF . kana-tu)
   '(#x4B0 . prolongedsound)
   '(#x4B1 . kana-A)
   '(#x4B2 . kana-I)
   '(#x4B3 . kana-U)
   '(#x4B4 . kana-E)
   '(#x4B5 . kana-O)
   '(#x4B6 . kana-KA)
   '(#x4B7 . kana-KI)
   '(#x4B8 . kana-KU)
   '(#x4B9 . kana-KE)
   '(#x4BA . kana-KO)
   '(#x4BB . kana-SA)
   '(#x4BC . kana-SHI)
   '(#x4BD . kana-SU)
   '(#x4BE . kana-SE)
   '(#x4BF . kana-SO)
   '(#x4C0 . kana-TA)
   '(#x4C1 . kana-TI)
   '(#x4C2 . kana-TU)
   '(#x4C3 . kana-TE)
   '(#x4C4 . kana-TO)
   '(#x4C5 . kana-NA)
   '(#x4C6 . kana-NI)
   '(#x4C7 . kana-NU)
   '(#x4C8 . kana-NE)
   '(#x4C9 . kana-NO)
   '(#x4CA . kana-HA)
   '(#x4CB . kana-HI)
   '(#x4CC . kana-HU)
   '(#x4CD . kana-HE)
   '(#x4CE . kana-HO)
   '(#x4CF . kana-MA)
   '(#x4D0 . kana-MI)
   '(#x4D1 . kana-MU)
   '(#x4D2 . kana-ME)
   '(#x4D3 . kana-MO)
   '(#x4D4 . kana-YA)
   '(#x4D5 . kana-YU)
   '(#x4D6 . kana-YO)
   '(#x4D7 . kana-RA)
   '(#x4D8 . kana-RI)
   '(#x4D9 . kana-RU)
   '(#x4DA . kana-RE)
   '(#x4DB . kana-RO)
   '(#x4DC . kana-WA)
   '(#x4DD . kana-N)
   '(#x4DE . voicedsound)
   '(#x4DF . semivoicedsound)
   '(#x5AC . Arabic-comma)
   '(#x5BB . Arabic-semicolon)
   '(#x5BF . Arabic-question-mark)
   '(#x5C1 . Arabic-hamza)
   '(#x5C2 . Arabic-maddaonalef)
   '(#x5C3 . Arabic-hamzaonalef)
   '(#x5C4 . Arabic-hamzaonwaw)
   '(#x5C5 . Arabic-hamzaunderalef)
   '(#x5C6 . Arabic-hamzaonyeh)
   '(#x5C7 . Arabic-alef)
   '(#x5C8 . Arabic-beh)
   '(#x5C9 . Arabic-tehmarbuta)
   '(#x5CA . Arabic-teh)
   '(#x5CB . Arabic-theh)
   '(#x5CC . Arabic-jeem)
   '(#x5CD . Arabic-hah)
   '(#x5CE . Arabic-khah)
   '(#x5CF . Arabic-dal)
   '(#x5D0 . Arabic-thal)
   '(#x5D1 . Arabic-ra)
   '(#x5D2 . Arabic-zain)
   '(#x5D3 . Arabic-seen)
   '(#x5D4 . Arabic-sheen)
   '(#x5D5 . Arabic-sad)
   '(#x5D6 . Arabic-dad)
   '(#x5D7 . Arabic-tah)
   '(#x5D8 . Arabic-zah)
   '(#x5D9 . Arabic-ain)
   '(#x5DA . Arabic-ghain)
   '(#x5E0 . Arabic-tatweel)
   '(#x5E1 . Arabic-feh)
   '(#x5E2 . Arabic-qaf)
   '(#x5E3 . Arabic-kaf)
   '(#x5E4 . Arabic-lam)
   '(#x5E5 . Arabic-meem)
   '(#x5E6 . Arabic-noon)
   '(#x5E7 . Arabic-heh)
   '(#x5E8 . Arabic-waw)
   '(#x5E9 . Arabic-alefmaksura)
   '(#x5EA . Arabic-yeh)
   '(#x5EB . Arabic-fathatan)
   '(#x5EC . Arabic-dammatan)
   '(#x5ED . Arabic-kasratan)
   '(#x5EE . Arabic-fatha)
   '(#x5EF . Arabic-damma)
   '(#x5F0 . Arabic-kasra)
   '(#x5F1 . Arabic-shadda)
   '(#x5F2 . Arabic-sukun)
   '(#x6A1 . Serbian-dje)
   '(#x6A2 . Macedonia-gje)
   '(#x6A3 . Cyrillic-io)
   '(#x6A4 . Ukranian-je)
   '(#x6A5 . Macedonia-dse)
   '(#x6A6 . Ukranian-i)
   '(#x6A7 . Ukranian-yi)
   '(#x6A8 . Cyrillic-je)
   '(#x6A9 . Cyrillic-lje)
   '(#x6AA . Cyrillic-nje)
   '(#x6AB . Serbian-tshe)
   '(#x6AC . Macedonia-kje)
   '(#x6AE . Byelorussian-shortu)
   '(#x6AF . Cyrillic-dzhe)
   '(#x6B0 . numerosign)
   '(#x6B1 . Serbian-DJE)
   '(#x6B2 . Macedonia-GJE)
   '(#x6B3 . Cyrillic-IO)
   '(#x6B4 . Ukranian-JE)
   '(#x6B5 . Macedonia-DSE)
   '(#x6B6 . Ukranian-I)
   '(#x6B7 . Ukrainian-YI)
   '(#x6B8 . Cyrillic-JE)
   '(#x6B9 . Cyrillic-LJE)
   '(#x6BA . Cyrillic-NJE)
   '(#x6BB . Serbian-TSHE)
   '(#x6BC . Macedonia-KJE)
   '(#x6BE . Byelorussian-SHORTU)
   '(#x6BF . Cyrillic-DZHE)
   '(#x6C0 . Cyrillic-yu)
   '(#x6C1 . Cyrillic-a)
   '(#x6C2 . Cyrillic-be)
   '(#x6C3 . Cyrillic-tse)
   '(#x6C4 . Cyrillic-de)
   '(#x6C5 . Cyrillic-ie)
   '(#x6C6 . Cyrillic-ef)
   '(#x6C7 . Cyrillic-ghe)
   '(#x6C8 . Cyrillic-ha)
   '(#x6C9 . Cyrillic-i)
   '(#x6CA . Cyrillic-shorti)
   '(#x6CB . Cyrillic-ka)
   '(#x6CC . Cyrillic-el)
   '(#x6CD . Cyrillic-em)
   '(#x6CE . Cyrillic-en)
   '(#x6CF . Cyrillic-o)
   '(#x6D0 . Cyrillic-pe)
   '(#x6D1 . Cyrillic-ya)
   '(#x6D2 . Cyrillic-er)
   '(#x6D3 . Cyrillic-es)
   '(#x6D4 . Cyrillic-te)
   '(#x6D5 . Cyrillic-u)
   '(#x6D6 . Cyrillic-zhe)
   '(#x6D7 . Cyrillic-ve)
   '(#x6D8 . Cyrillic-softsign)
   '(#x6D9 . Cyrillic-yeru)
   '(#x6DA . Cyrillic-ze)
   '(#x6DB . Cyrillic-sha)
   '(#x6DC . Cyrillic-e)
   '(#x6DD . Cyrillic-shcha)
   '(#x6DE . Cyrillic-che)
   '(#x6DF . Cyrillic-hardsign)
   '(#x6E0 . Cyrillic-YU)
   '(#x6E1 . Cyrillic-A)
   '(#x6E2 . Cyrillic-BE)
   '(#x6E3 . Cyrillic-TSE)
   '(#x6E4 . Cyrillic-DE)
   '(#x6E5 . Cyrillic-IE)
   '(#x6E6 . Cyrillic-EF)
   '(#x6E7 . Cyrillic-GHE)
   '(#x6E8 . Cyrillic-HA)
   '(#x6E9 . Cyrillic-I)
   '(#x6EA . Cyrillic-SHORTI)
   '(#x6EB . Cyrillic-KA)
   '(#x6EC . Cyrillic-EL)
   '(#x6ED . Cyrillic-EM)
   '(#x6EE . Cyrillic-EN)
   '(#x6EF . Cyrillic-O)
   '(#x6F0 . Cyrillic-PE)
   '(#x6F1 . Cyrillic-YA)
   '(#x6F2 . Cyrillic-ER)
   '(#x6F3 . Cyrillic-ES)
   '(#x6F4 . Cyrillic-TE)
   '(#x6F5 . Cyrillic-U)
   '(#x6F6 . Cyrillic-ZHE)
   '(#x6F7 . Cyrillic-VE)
   '(#x6F8 . Cyrillic-SOFTSIGN)
   '(#x6F9 . Cyrillic-YERU)
   '(#x6FA . Cyrillic-ZE)
   '(#x6FB . Cyrillic-SHA)
   '(#x6FC . Cyrillic-E)
   '(#x6FD . Cyrillic-SHCHA)
   '(#x6FE . Cyrillic-CHE)
   '(#x6FF . Cyrillic-HARDSIGN)
   '(#x7A1 . Greek-ALPHAaccent)
   '(#x7A2 . Greek-EPSILONaccent)
   '(#x7A3 . Greek-ETAaccent)
   '(#x7A4 . Greek-IOTAaccent)
   '(#x7A5 . Greek-IOTAdiaeresis)
   '(#x7A7 . Greek-OMICRONaccent)
   '(#x7A8 . Greek-UPSILONaccent)
   '(#x7A9 . Greek-UPSILONdieresis)
   '(#x7AB . Greek-OMEGAaccent)
   '(#x7AE . Greek-accentdieresis)
   '(#x7AF . Greek-horizbar)
   '(#x7B1 . Greek-alphaaccent)
   '(#x7B2 . Greek-epsilonaccent)
   '(#x7B3 . Greek-etaaccent)
   '(#x7B4 . Greek-iotaaccent)
   '(#x7B5 . Greek-iotadieresis)
   '(#x7B6 . Greek-iotaaccentdieresis)
   '(#x7B7 . Greek-omicronaccent)
   '(#x7B8 . Greek-upsilonaccent)
   '(#x7B9 . Greek-upsilondieresis)
   '(#x7BA . Greek-upsilonaccentdieresis)
   '(#x7BB . Greek-omegaaccent)
   '(#x7C1 . Greek-ALPHA)
   '(#x7C2 . Greek-BETA)
   '(#x7C3 . Greek-GAMMA)
   '(#x7C4 . Greek-DELTA)
   '(#x7C5 . Greek-EPSILON)
   '(#x7C6 . Greek-ZETA)
   '(#x7C7 . Greek-ETA)
   '(#x7C8 . Greek-THETA)
   '(#x7C9 . Greek-IOTA)
   '(#x7CA . Greek-KAPPA)
   '(#x7CB . Greek-LAMBDA)
   '(#x7CC . Greek-MU)
   '(#x7CD . Greek-NU)
   '(#x7CE . Greek-XI)
   '(#x7CF . Greek-OMICRON)
   '(#x7D0 . Greek-PI)
   '(#x7D1 . Greek-RHO)
   '(#x7D2 . Greek-SIGMA)
   '(#x7D4 . Greek-TAU)
   '(#x7D5 . Greek-UPSILON)
   '(#x7D6 . Greek-PHI)
   '(#x7D7 . Greek-CHI)
   '(#x7D8 . Greek-PSI)
   '(#x7D9 . Greek-OMEGA)
   '(#x7E1 . Greek-alpha)
   '(#x7E2 . Greek-beta)
   '(#x7E3 . Greek-gamma)
   '(#x7E4 . Greek-delta)
   '(#x7E5 . Greek-epsilon)
   '(#x7E6 . Greek-zeta)
   '(#x7E7 . Greek-eta)
   '(#x7E8 . Greek-theta)
   '(#x7E9 . Greek-iota)
   '(#x7EA . Greek-kappa)
   '(#x7EB . Greek-lambda)
   '(#x7EC . Greek-mu)
   '(#x7ED . Greek-nu)
   '(#x7EE . Greek-xi)
   '(#x7EF . Greek-omicron)
   '(#x7F0 . Greek-pi)
   '(#x7F1 . Greek-rho)
   '(#x7F2 . Greek-sigma)
   '(#x7F3 . Greek-finalsmallsigma)
   '(#x7F4 . Greek-tau)
   '(#x7F5 . Greek-upsilon)
   '(#x7F6 . Greek-phi)
   '(#x7F7 . Greek-chi)
   '(#x7F8 . Greek-psi)
   '(#x7F9 . Greek-omega)
   '(#x8A1 . leftradical)
   '(#x8A2 . topleftradical)
   '(#x8A3 . horizconnector)
   '(#x8A4 . topintegral)
   '(#x8A5 . botintegral)
   '(#x8A6 . vertconnector)
   '(#x8A7 . topleftsqbracket)
   '(#x8A8 . botleftsqbracket)
   '(#x8A9 . toprightsqbracket)
   '(#x8AA . botrightsqbracket)
   '(#x8AB . topleftparens)
   '(#x8AC . botleftparens)
   '(#x8AD . toprightparens)
   '(#x8AE . botrightparens)
   '(#x8AF . leftmiddlecurlybrace)
   '(#x8B0 . rightmiddlecurlybrace)
   '(#x8B1 . topleftsummation)
   '(#x8B2 . botleftsummation)
   '(#x8B3 . topvertsummationconnector)
   '(#x8B4 . botvertsummationconnector)
   '(#x8B5 . toprightsummation)
   '(#x8B6 . botrightsummation)
   '(#x8B7 . rightmiddlesummation)
   '(#x8BC . lessthanequal)
   '(#x8BD . notequal)
   '(#x8BE . greaterthanequal)
   '(#x8BF . integral)
   '(#x8C0 . therefore)
   '(#x8C1 . variation)
   '(#x8C2 . infinity)
   '(#x8C5 . nabla)
   '(#x8C8 . approximate)
   '(#x8C9 . similarequal)
   '(#x8CD . ifonlyif)
   '(#x8CE . implies)
   '(#x8CF . identical)
   '(#x8D6 . radical)
   '(#x8DA . includedin)
   '(#x8DB . includes)
   '(#x8DC . intersection)
   '(#x8DD . union)
   '(#x8DE . logicaland)
   '(#x8DF . logicalor)
   '(#x8EF . partialderivative)
   '(#x8F6 . function)
   '(#x8FB . leftarrow)
   '(#x8FC . uparrow)
   '(#x8FD . rightarrow)
   '(#x8FE . downarrow)
   '(#x9DF . blank)
   '(#x9E0 . soliddiamond)
   '(#x9E1 . checkerboard)
   '(#x9E2 . ht)
   '(#x9E3 . ff)
   '(#x9E4 . cr)
   '(#x9E5 . lf)
   '(#x9E8 . nl)
   '(#x9E9 . vt)
   '(#x9EA . lowrightcorner)
   '(#x9EB . uprightcorner)
   '(#x9EC . upleftcorner)
   '(#x9ED . lowleftcorner)
   '(#x9EE . crossinglines)
   '(#x9EF . horizlinescan1)
   '(#x9F0 . horizlinescan3)
   '(#x9F1 . horizlinescan5)
   '(#x9F2 . horizlinescan7)
   '(#x9F3 . horizlinescan9)
   '(#x9F4 . leftt)
   '(#x9F5 . rightt)
   '(#x9F6 . bott)
   '(#x9F7 . topt)
   '(#x9F8 . vertbar)
   '(#xAA1 . emspace)
   '(#xAA2 . enspace)
   '(#xAA3 . em3space)
   '(#xAA4 . em4space)
   '(#xAA5 . digitspace)
   '(#xAA6 . punctspace)
   '(#xAA7 . thinspace)
   '(#xAA8 . hairspace)
   '(#xAA9 . emdash)
   '(#xAAA . endash)
   '(#xAAC . signifblank)
   '(#xAAE . ellipsis)
   '(#xAAF . doubbaselinedot)
   '(#xAB0 . onethird)
   '(#xAB1 . twothirds)
   '(#xAB2 . onefifth)
   '(#xAB3 . twofifths)
   '(#xAB4 . threefifths)
   '(#xAB5 . fourfifths)
   '(#xAB6 . onesixth)
   '(#xAB7 . fivesixths)
   '(#xAB8 . careof)
   '(#xABB . figdash)
   '(#xABC . leftanglebracket)
   '(#xABD . decimalpoint)
   '(#xABE . rightanglebracket)
   '(#xABF . marker)
   '(#xAC3 . oneeighth)
   '(#xAC4 . threeeighths)
   '(#xAC5 . fiveeighths)
   '(#xAC6 . seveneighths)
   '(#xAC9 . trademark)
   '(#xACA . signaturemark)
   '(#xACB . trademarkincircle)
   '(#xACC . leftopentriangle)
   '(#xACD . rightopentriangle)
   '(#xACE . emopencircle)
   '(#xACF . emopenrectangle)
   '(#xAD0 . leftsinglequotemark)
   '(#xAD1 . rightsinglequotemark)
   '(#xAD2 . leftdoublequotemark)
   '(#xAD3 . rightdoublequotemark)
   '(#xAD4 . prescription)
   '(#xAD6 . minutes)
   '(#xAD7 . seconds)
   '(#xAD9 . latincross)
   '(#xADA . hexagram)
   '(#xADB . filledrectbullet)
   '(#xADC . filledlefttribullet)
   '(#xADD . filledrighttribullet)
   '(#xADE . emfilledcircle)
   '(#xADF . emfilledrect)
   '(#xAE0 . enopencircbullet)
   '(#xAE1 . enopensquarebullet)
   '(#xAE2 . openrectbullet)
   '(#xAE3 . opentribulletup)
   '(#xAE4 . opentribulletdown)
   '(#xAE5 . openstar)
   '(#xAE6 . enfilledcircbullet)
   '(#xAE7 . enfilledsqbullet)
   '(#xAE8 . filledtribulletup)
   '(#xAE9 . filledtribulletdown)
   '(#xAEA . leftpointer)
   '(#xAEB . rightpointer)
   '(#xAEC . club)
   '(#xAED . diamond)
   '(#xAEE . heart)
   '(#xAF0 . maltesecross)
   '(#xAF1 . dagger)
   '(#xAF2 . doubledagger)
   '(#xAF3 . checkmark)
   '(#xAF4 . ballotcross)
   '(#xAF5 . musicalsharp)
   '(#xAF6 . musicalflat)
   '(#xAF7 . malesymbol)
   '(#xAF8 . femalesymbol)
   '(#xAF9 . telephone)
   '(#xAFA . telephonerecorder)
   '(#xAFB . phonographcopyright)
   '(#xAFC . caret)
   '(#xAFD . singlelowquotemark)
   '(#xAFE . doublelowquotemark)
   '(#xAFF . cursor)
   '(#xBA3 . leftcaret)
   '(#xBA6 . rightcaret)
   '(#xBA8 . downcaret)
   '(#xBA9 . upcaret)
   '(#xBC0 . overbar)
   '(#xBC2 . downtack)
   '(#xBC3 . upshoe)
   '(#xBC4 . downstile)
   '(#xBC6 . underbar)
   '(#xBCA . jot)
   '(#xBCC . quad)
   '(#xBCE . uptack)
   '(#xBCF . circle)
   '(#xBD3 . upstile)
   '(#xBD6 . downshoe)
   '(#xBD8 . rightshoe)
   '(#xBDA . leftshoe)
   '(#xBDC . lefttack)
   '(#xBFC . righttack)
   '(#xCDF . hebrew-doublelowline)
   '(#xCE0 . hebrew-aleph)
   '(#xCE1 . hebrew-beth)
   '(#xCE2 . hebrew-gimmel)
   '(#xCE3 . hebrew-daleth)
   '(#xCE4 . hebrew-he)
   '(#xCE5 . hebrew-waw)
   '(#xCE6 . hebrew-zayin)
   '(#xCE7 . hebrew-het)
   '(#xCE8 . hebrew-teth)
   '(#xCE9 . hebrew-yod)
   '(#xCEA . hebrew-finalkaph)
   '(#xCEB . hebrew-kaph)
   '(#xCEC . hebrew-lamed)
   '(#xCED . hebrew-finalmem)
   '(#xCEE . hebrew-mem)
   '(#xCEF . hebrew-finalnun)
   '(#xCF0 . hebrew-nun)
   '(#xCF1 . hebrew-samekh)
   '(#xCF2 . hebrew-ayin)
   '(#xCF3 . hebrew-finalpe)
   '(#xCF4 . hebrew-pe)
   '(#xCF5 . hebrew-finalzadi)
   '(#xCF6 . hebrew-zadi)
   '(#xCF7 . hebrew-qoph)
   '(#xCF8 . hebrew-resh)
   '(#xCF9 . hebrew-shin)
   '(#xCFA . hebrew-taf)
   '(#xFF08 . BackSpace)
   '(#xFF09 . Tab)
   '(#xFF0A . Linefeed)
   '(#xFF0B . Clear)
   '(#xFF0D . Return)
   '(#xFF13 . Pause)
   '(#xFF14 . Scroll-Lock)
   '(#xFF1B . Escape)
   '(#xFF20 . Multi-key)
   '(#xFF21 . Kanji)
   '(#xFF22 . Muhenkan)
   '(#xFF23 . Henkan)
   '(#xFF24 . Romaji)
   '(#xFF25 . Hiragana)
   '(#xFF26 . Katakana)
   '(#xFF27 . Hiragana-Katakana)
   '(#xFF28 . Zenkaku)
   '(#xFF29 . Hankaku)
   '(#xFF2A . Zenkaku-Hankaku)
   '(#xFF2B . Touroku)
   '(#xFF2C . Massyo)
   '(#xFF2D . Kana-Lock)
   '(#xFF2E . Kana-Shift)
   '(#xFF2F . Eisu-Shift)
   '(#xFF30 . Eisu-toggle)
   '(#xFF50 . Home)
   '(#xFF51 . Left)
   '(#xFF52 . Up)
   '(#xFF53 . Right)
   '(#xFF54 . Down)
   '(#xFF55 . Prior)
   '(#xFF56 . Next)
   '(#xFF57 . End)
   '(#xFF58 . Begin)
   '(#xFF60 . Select)
   '(#xFF61 . Print)
   '(#xFF62 . Execute)
   '(#xFF63 . Insert)
   '(#xFF65 . Undo)
   '(#xFF66 . Redo)
   '(#xFF67 . Menu)
   '(#xFF68 . Find)
   '(#xFF69 . Stop)			;originally called Cancel
   '(#xFF6A . Help)
   '(#xFF6B . Break)
   '(#xFF7E . script-switch)
   '(#xFF7F . Num-Lock)
   '(#xFF80 . KP-Space)
   '(#xFF89 . KP-Tab)
   '(#xFF8D . KP-Enter)
   '(#xFF91 . KP-F1)
   '(#xFF92 . KP-F2)
   '(#xFF93 . KP-F3)
   '(#xFF94 . KP-F4)
   '(#xFFAA . KP-Multiply)
   '(#xFFAB . KP-Add)
   '(#xFFAC . KP-Separator)
   '(#xFFAD . KP-Subtract)
   '(#xFFAE . KP-Decimal)
   '(#xFFAF . KP-Divide)
   '(#xFFB0 . KP-0)
   '(#xFFB1 . KP-1)
   '(#xFFB2 . KP-2)
   '(#xFFB3 . KP-3)
   '(#xFFB4 . KP-4)
   '(#xFFB5 . KP-5)
   '(#xFFB6 . KP-6)
   '(#xFFB7 . KP-7)
   '(#xFFB8 . KP-8)
   '(#xFFB9 . KP-9)
   '(#xFFBD . KP-Equal)
   '(#xFFBE . F1)
   '(#xFFBF . F2)
   '(#xFFC0 . F3)
   '(#xFFC1 . F4)
   '(#xFFC2 . F5)
   '(#xFFC3 . F6)
   '(#xFFC4 . F7)
   '(#xFFC5 . F8)
   '(#xFFC6 . F9)
   '(#xFFC7 . F10)
   '(#xFFC8 . F11)
   '(#xFFC9 . F12)
   '(#xFFCA . F13)
   '(#xFFCB . F14)
   '(#xFFCC . F15)
   '(#xFFCD . F16)
   '(#xFFCE . F17)
   '(#xFFCF . F18)
   '(#xFFD0 . F19)
   '(#xFFD1 . F20)
   '(#xFFD2 . F21)
   '(#xFFD3 . F22)
   '(#xFFD4 . F23)
   '(#xFFD5 . F24)
   '(#xFFD6 . F25)
   '(#xFFD7 . F26)
   '(#xFFD8 . F27)
   '(#xFFD9 . F28)
   '(#xFFDA . F29)
   '(#xFFDB . F30)
   '(#xFFDC . F31)
   '(#xFFDD . F32)
   '(#xFFDE . F33)
   '(#xFFDF . F34)
   '(#xFFE0 . F35)
   '(#xFFE1 . Shift-L)
   '(#xFFE2 . Shift-R)
   '(#xFFE3 . Control-L)
   '(#xFFE4 . Control-R)
   '(#xFFE5 . Caps-Lock)
   '(#xFFE6 . Shift-Lock)
   '(#xFFE7 . Meta-L)
   '(#xFFE8 . Meta-R)
   '(#xFFE9 . Alt-L)
   '(#xFFEA . Alt-R)
   '(#xFFEB . Super-L)
   '(#xFFEC . Super-R)
   '(#xFFED . Hyper-L)
   '(#xFFEE . Hyper-R)
   '(#xFFFF . Delete)
   '(#x8000A8 . mute-acute)
   '(#x8000A9 . mute-grave)
   '(#x8000AA . mute-asciicircum)
   '(#x8000AB . mute-diaeresis)
   '(#x8000AC . mute-asciitilde)
   '(#x8000AF . lira)
   '(#x8000BE . guilder)
   '(#x8000EE . Ydiaeresis)
   '(#x8000F6 . longminus)
   '(#x8000FC . block)
   '(#x80FF48 . hpModelock1)
   '(#x80FF49 . hpModelock2)
   '(#x80FF6C . Reset)
   '(#x80FF6D . System)
   '(#x80FF6E . User)
   '(#x80FF6F . ClearLine)
   '(#x80FF70 . InsertLine)
   '(#x80FF71 . DeleteLine)
   '(#x80FF72 . InsertChar)
   '(#x80FF73 . DeleteChar)
   '(#x80FF74 . BackTab)
   '(#x80FF75 . KP-BackTab)
   '(#x80FF76 . Ext16bit-L)
   '(#x80FF77 . Ext16bit-R)
   '(#x84FF02 . osfCopy)
   '(#x84FF03 . osfCut)
   '(#x84FF04 . osfPaste)
   '(#x84FF08 . osfBackSpace)
   '(#x84FF0B . osfClear)
   '(#x84FF31 . osfAddMode)
   '(#x84FF32 . osfPrimaryPaste)
   '(#x84FF33 . osfQuickPaste)
   '(#x84FF41 . osfPageUp)
   '(#x84FF42 . osfPageDown)
   '(#x84FF44 . osfActivate)
   '(#x84FF45 . osfMenuBar)
   '(#x84FF51 . osfLeft)
   '(#x84FF52 . osfUp)
   '(#x84FF53 . osfRight)
   '(#x84FF54 . osfDown)
   '(#x84FF57 . osfEndLine)
   '(#x84FF58 . osfBeginLine)
   '(#x84FF60 . osfSelect)
   '(#x84FF63 . osfInsert)
   '(#x84FF65 . osfUndo)
   '(#x84FF67 . osfMenu)
   '(#x84FF69 . osfCancel)
   '(#x84FF6A . osfHelp)
   '(#x84FFFF . osfDelete)
   '(#xFFFFFF . VoidSymbol)))