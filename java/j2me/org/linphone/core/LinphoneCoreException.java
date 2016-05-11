/*
LinphoneCoreException.java
Developed pursuant to contract FCC15C0008 as open source software under GNU General Public License version 2.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/
package org.linphone.core;


public class LinphoneCoreException extends Exception {
	Throwable mE;
	public LinphoneCoreException() {
		super();
	}

	public LinphoneCoreException(String detailMessage) {
		super(detailMessage);

	}
	public LinphoneCoreException(Throwable e) {
		this(e.getClass().getName()+" "+ e.getMessage());
		mE = e;
	}

	public LinphoneCoreException(String detailMessage,Throwable e) {
		super(detailMessage + "caused by ["+e.getClass().getName()+" "+ e.getMessage()+"]");
		mE = e;
	}

	public void printStackTrace() {
		super.printStackTrace();
		if (mE!=null) mE.printStackTrace();
	}
	

}
