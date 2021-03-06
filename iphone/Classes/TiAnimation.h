/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiProxy.h"
#import "TiPoint.h"
#import "TiColor.h"
#import "ListenerEntry.h"
#import <QuartzCore/QuartzCore.h>

@class TiViewProxy;
@class TiAnimation;

@protocol TiAnimationDelegate

@optional

-(BOOL)animationShouldTransition:(id)sender;
-(void)animationWillStart:(id)sender;
-(void)animationDidStart:(id)sender;
-(void)animationWillComplete:(id)sender;
-(void)animationDidComplete:(id)sender;

@end


@interface TiAnimation : TiProxy {
@private
	NSNumber	*zIndex;
	NSNumber	*left;
	NSNumber	*right;
	NSNumber	*top;
	NSNumber	*bottom;
	NSNumber	*width;
	NSNumber	*height;
	NSNumber	*duration;
	TiPoint		*center;
	TiColor		*backgroundColor;
	TiColor		*color;
	NSNumber	*opacity;
	NSNumber	*opaque;
	NSNumber	*visible;
	NSNumber	*curve;
	NSNumber	*repeat;
	NSNumber	*autoreverse;
	NSNumber	*delay;
	TiProxy		*transform;
	NSNumber	*transition;
	TiViewProxy	*view;

	// this is a temporary function passed in
	ListenerEntry *callback;
	
	NSObject<TiAnimationDelegate> *delegate;
	
	// for autoreverse
	UIView *autoreverseView;
	id transformMatrix;
}

@property(nonatomic,assign,readwrite) NSObject<TiAnimationDelegate> *delegate;

// animatable properties against what is being animated
@property(nonatomic,retain,readwrite) NSNumber	*zIndex;
@property(nonatomic,retain,readwrite) NSNumber	*left;
@property(nonatomic,retain,readwrite) NSNumber	*right;
@property(nonatomic,retain,readwrite) NSNumber	*top;
@property(nonatomic,retain,readwrite) NSNumber	*bottom;
@property(nonatomic,retain,readwrite) NSNumber	*width;
@property(nonatomic,retain,readwrite) NSNumber	*height;
@property(nonatomic,retain,readwrite) NSNumber	*duration;
@property(nonatomic,retain,readwrite) TiPoint	*center;
@property(nonatomic,retain,readwrite) TiColor	*color;
@property(nonatomic,retain,readwrite) TiColor	*backgroundColor;
@property(nonatomic,retain,readwrite) NSNumber	*opacity;
@property(nonatomic,retain,readwrite) NSNumber	*opaque;
@property(nonatomic,retain,readwrite) NSNumber	*visible;

// properties that control the animation 
@property(nonatomic,retain,readwrite) NSNumber	*curve;
@property(nonatomic,retain,readwrite) NSNumber	*repeat;
@property(nonatomic,retain,readwrite) NSNumber	*autoreverse;
@property(nonatomic,retain,readwrite) NSNumber	*delay;
@property(nonatomic,retain,readwrite) TiProxy	*transform;
@property(nonatomic,retain,readwrite) NSNumber	*transition;
@property(nonatomic,retain,readwrite) TiProxy	*view;

+(TiAnimation*)animationFromArg:(id)args context:(id<TiEvaluator>)context create:(BOOL)yn;

-(id)initWithDictionary:(NSDictionary*)properties context:(id<TiEvaluator>)context;

-(id)initWithDictionary:(NSDictionary*)properties context:(id<TiEvaluator>)context callback:(KrollCallback*)callback;

-(void)animate:(id)args;

-(BOOL)isTransitionAnimation;

@end
