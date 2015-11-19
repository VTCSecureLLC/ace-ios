/* UIPauseButton.h
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */     

#import "UIToggleButton.h"

#include "linphone/linphonecore.h"

typedef enum _UIChatButtonType {
    UIChatButtonType_Call,
    UIChatButtonType_CurrentCall,
    UIChatButtonType_SIMPLE,
    UIChatButtonType_Conference
} UIChatButtonType;

@interface UIChatButton : UIToggleButton<UIToggleButtonDelegate> {
    @private
    UIChatButtonType type;
    LinphoneCall* call;
}

- (void)setType:(UIChatButtonType) type call:(LinphoneCall*)call;

-(BOOL) dismissKeyboard;
-(BOOL) showKeyboard;
@end
