/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIWebView.h"
#import "TiUIWebViewProxy.h"

#import "TiUtils.h"
#import "TiProxy.h"
#import "SBJSON.h"
#import "TiHost.h"
#import "Webcolor.h"
#import "TiBlob.h"
#import "TiFile.h"
#import "Mimetypes.h"

extern NSString * const TI_APPLICATION_ID;
NSString * const kTitaniumJavascript = @"Ti.App={};Ti.API={};Ti.App._listeners={};Ti.App._listener_id=1;Ti.App.id=Ti.appId;Ti.App._xhr=XMLHttpRequest;Ti._broker=function(module,method,data){try{var url='app://'+Ti.appId+'/_TiA0_'+Ti.pageToken+'/'+module+'/'+method+'?'+Ti.App._JSON(data,1);var xhr=new Ti.App._xhr();xhr.open('GET',url,false);xhr.send()}catch(X){}};Ti._hexish=function(a){var r='';var e=a.length;var c=0;var h;while(c<e){h=a.charCodeAt(c++).toString(16);r+='\\\\u';var l=4-h.length;while(l-->0){r+='0'};r+=h}return r};Ti._bridgeEnc=function(o){return'<'+Ti._hexish(o)+'>'};Ti.App._JSON=function(object,bridge){var type=typeof object;switch(type){case'undefined':case'function':case'unknown':return undefined;case'number':case'boolean':return object;case'string':if(bridge===1)return Ti._bridgeEnc(object);return'\"'+object.replace(/\"/g,'\\\\\"').replace(/\\n/g,'\\\\n').replace(/\\r/g,'\\\\r')+'\"'}if((object===null)||(object.nodeType==1))return'null';if(object.constructor.toString().indexOf('Date')!=-1){return'new Date('+object.getTime()+')'}if(object.constructor.toString().indexOf('Array')!=-1){var res='[';var pre='';var len=object.length;for(var i=0;i<len;i++){var value=object[i];if(value!==undefined)value=Ti.App._JSON(value,bridge);if(value!==undefined){res+=pre+value;pre=', '}}return res+']'}var objects=[];for(var prop in object){var value=object[prop];if(value!==undefined){value=Ti.App._JSON(value,bridge)}if(value!==undefined){objects.push(Ti.App._JSON(prop,bridge)+': '+value)}}return'{'+objects.join(',')+'}'};Ti.App._dispatchEvent=function(type,evtid,evt){var listeners=Ti.App._listeners[type];if(listeners){for(var c=0;c<listeners.length;c++){var entry=listeners[c];if(entry.id==evtid){entry.callback.call(entry.callback,evt)}}}};Ti.App.fireEvent=function(name,evt){Ti._broker('App','fireEvent',{name:name,event:evt})};Ti.API.log=function(a,b){Ti._broker('API','log',{level:a,message:b})};Ti.API.debug=function(e){Ti._broker('API','log',{level:'debug',message:e})};Ti.API.error=function(e){Ti._broker('API','log',{level:'error',message:e})};Ti.API.info=function(e){Ti._broker('API','log',{level:'info',message:e})};Ti.API.fatal=function(e){Ti._broker('API','log',{level:'fatal',message:e})};Ti.API.warn=function(e){Ti._broker('API','log',{level:'warn',message:e})};Ti.App.addEventListener=function(name,fn){var listeners=Ti.App._listeners[name];if(typeof(listeners)=='undefined'){listeners=[];Ti.App._listeners[name]=listeners}var newid=Ti.pageToken+Ti.App._listener_id++;listeners.push({callback:fn,id:newid});Ti._broker('App','addEventListener',{name:name,id:newid})};Ti.App.removeEventListener=function(name,fn){var listeners=Ti.App._listeners[name];if(listeners){for(var c=0;c<listeners.length;c++){var entry=listeners[c];if(entry.callback==fn){listeners.splice(c,1);Ti._broker('App','removeEventListener',{name:name,id:entry.id});break}}}};";

 
@implementation TiUIWebView

-(void)unregister
{
	if (pageToken!=nil)
	{
		[[self.proxy _host] unregisterContext:self forToken:pageToken];
		RELEASE_TO_NIL(pageToken);
	}
}

-(void)dealloc
{
	if (webview!=nil)
	{
		webview.delegate = nil;
		
		// per doc, must stop webview load before releasing
		if (webview.loading)
		{
			[webview stopLoading];
		}
	}
	if (listeners!=nil)
	{
		for (TiProxy *listener in listeners)
		{
		}
		RELEASE_TO_NIL(listeners);
	}
	RELEASE_TO_NIL(webview);
	RELEASE_TO_NIL(url);
	RELEASE_TO_NIL(spinner);
	RELEASE_TO_NIL(appModule);
	[self unregister];
	[super dealloc];
}

-(BOOL)isURLRemote
{
	NSString *scheme = [url scheme];
	return [scheme hasPrefix:@"http"];
}

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	// webview is a little _special_ so we need to intercept
	// his events and handle them as well as dispatch directly
	// to the webview to handle inside HTML
	UIView *view = [super hitTest:point withEvent:event];
	id desc = [[view class] description];
	// we check the description since the actual class is a private
	// class UIWebDocumentView and we can't worry about apple triggering
	// their private apis sound alarm
	if ([desc hasPrefix:@"UIWeb"])
	{
		delegateView = view;
		return self;
	}
	else
	{
		delegateView = nil;
	}
	return view;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesBegan:touches withEvent:event];
	if (delegateView!=nil)
	{
		[delegateView touchesBegan:touches withEvent:event];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesMoved:touches withEvent:event];
	if (delegateView!=nil)
	{
		[delegateView touchesMoved:touches withEvent:event];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesEnded:touches withEvent:event];
	if (delegateView!=nil)
	{
		[delegateView touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesCancelled:touches withEvent:event];
	if (delegateView!=nil)
	{
		[delegateView touchesCancelled:touches withEvent:event];
	}
}


-(UIWebView*)webview 
{
	if (webview==nil)
	{
		webview = [[UIWebView alloc] initWithFrame:CGRectZero];
		webview.delegate = self;
		webview.opaque = NO;
		webview.backgroundColor = [UIColor whiteColor];
		[self addSubview:webview];
		
		// only show the loading indicator if it's a remote URL
		if ([self isURLRemote])
		{
			spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
			[spinner setHidesWhenStopped:YES];
			spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			[self addSubview:spinner];
			[spinner sizeToFit];
			[spinner startAnimating];
		}
	}
	return webview;
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
	if (webview!=nil)
	{
		[TiUtils setView:webview positionRect:bounds];
		
		if (spinner!=nil)
		{
			spinner.center = self.center;
		}
		
		[[self webview] stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.body.style.minWidth='%fpx';document.body.style.minHeight='%fpx';",bounds.size.width-8,bounds.size.height-16]];
	}
}

-(NSURL*)fileURLToAppURL:(NSURL*)url_
{
	NSString *basepath = [[NSBundle mainBundle] resourcePath];
	NSString *urlstr = [url_ path];
	NSString *path = [urlstr stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",basepath] withString:@""];
	if ([path hasPrefix:@"/"])
	{
		path = [path substringFromIndex:1];
	}
	return [NSURL URLWithString:[NSString stringWithFormat:@"app://%@/%@",TI_APPLICATION_ID,path]];
}

-(NSString*)titaniumInjection
{
	NSMutableString *html = [[[NSMutableString alloc] init] autorelease];
	[html appendString:@"<script id='titanium_injection'>"];
	[html appendFormat:@"window.Titanium={};window.Ti=Titanium;Ti.pageToken=%@;Ti.appId='%@';",pageToken,TI_APPLICATION_ID];
	[html appendString:kTitaniumJavascript];
	[html appendString:@"</script>"];
	return html;
}

-(void)prepareInjection
{
	RELEASE_TO_NIL(pageToken);
	[self unregister];
	pageToken = [[NSString stringWithFormat:@"%d",[self hash]] retain];
	[[self.proxy _host] registerContext:self forToken:pageToken];
}

-(void)loadHTML:(NSString*)content 
	   encoding:(NSStringEncoding)encoding 
	   textEncodingName:(NSString*)textEncodingName
	   mimeType:(NSString*)mimeType
{
	[self prepareInjection];
	NSMutableString *html = [[NSMutableString alloc] initWithCapacity:[content length]+2000];
	
	// attempt to make well-formed HTML and inject in our Titanium bridge code
	// However, we only do this if the content looks like HTML
	NSRange range = [content rangeOfString:@"<html"];
	if (range.location!=NSNotFound)
	{
		BOOL found = NO;
		NSRange nextRange = [content rangeOfString:@">" options:0 range:NSMakeRange(range.location, [content length]-range.location) locale:nil];
		if (nextRange.location!=NSNotFound)
		{
			[html appendString:[content substringToIndex:nextRange.location+1]];
			[html appendString:[self titaniumInjection]];
			[html appendString:[content substringFromIndex:nextRange.location+1]];
			found = YES;
		}
		if (found==NO)
		{
			// oh well, just jack it in
			[html appendString:[self titaniumInjection]];
			[html appendString:content];
		}
	}
	
	NSURL *relativeURL = [self fileURLToAppURL:url];
	
	if (url!=nil)
	{
		[[self webview] loadHTMLString:html baseURL:relativeURL];
	}
	else
	{
		[[self webview] loadData:[html dataUsingEncoding:encoding] MIMEType:mimeType textEncodingName:textEncodingName baseURL:relativeURL];
	}
	if (scalingOverride==NO)
	{
		[[self webview] setScalesPageToFit:NO];
	}
	[html release];
}


#pragma mark Public APIs

-(id)url
{
	return url;
}

-(void)setBackgroundColor_:(id)color
{
	UIColor *c = UIColorWebColorNamed(color);
	[self setBackgroundColor:c];
	[[self webview] setBackgroundColor:c];
}

-(void)setHtml_:(NSString*)content
{
	[self loadHTML:content encoding:NSUTF8StringEncoding textEncodingName:@"utf-8" mimeType:@"text/html"];
}

-(void)setData_:(id)args
{
	RELEASE_TO_NIL(url);
	[self unregister];
	ENSURE_SINGLE_ARG(args,NSObject);
	if ([args isKindOfClass:[TiBlob class]])
	{
		if (scalingOverride==NO)
		{
			[[self webview] setScalesPageToFit:YES];
		}
		
		TiBlob *blob = (TiBlob*)args;
		TiBlobType type = [blob type];
		switch (type)
		{
			case TiBlobTypeData:
			{
				[[self webview] loadData:[blob data] MIMEType:[blob mimeType] textEncodingName:@"utf-8" baseURL:nil];
				break;
			}
			case TiBlobTypeFile:
			{
				url = [[NSURL fileURLWithPath:[blob path]] retain];
				[[self webview] loadRequest:[NSURLRequest requestWithURL:url]];
				break;
			}
			default:
			{
				[self.proxy throwException:@"invalid blob type" subreason:[NSString stringWithFormat:@"expected either file or data blob, was: %d",type] location:CODELOCATION];
			}
		}
	}
	else if ([args isKindOfClass:[TiFile class]])
	{
		TiFile *file = (TiFile*)args;
		url = [[NSURL fileURLWithPath:[file path]] retain];
		if (scalingOverride==NO)
		{
			[[self webview] setScalesPageToFit:YES];
		}
		[[self webview] loadRequest:[NSURLRequest requestWithURL:url]];
	}
	else
	{
		[self.proxy throwException:@"invalid datatype" subreason:[NSString stringWithFormat:@"expected a TiBlob, was: %@",[args class]] location:CODELOCATION];
	}
}

-(void)setScalesPageToFit_:(id)args
{
	// allow the user to overwrite the scale (usually if local)
	BOOL scaling = [TiUtils boolValue:args];
	scalingOverride = YES;
	[[self webview] setScalesPageToFit:scaling];
}

-(void)setUrl_:(id)args
{
	RELEASE_TO_NIL(url);
	ENSURE_SINGLE_ARG(args,NSString);
	
	url = [TiUtils toURL:args proxy:(TiProxy*)self.proxy];
	
	[self unregister];
	
	if ([self isURLRemote])
	{
		[url retain];
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		[[self webview] loadRequest:request];
		if (scalingOverride==NO)
		{
			[[self webview] setScalesPageToFit:YES];
		}
	}
	else
	{
		NSString *html = nil;
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSString *mimeType = [Mimetypes mimeTypeForExtension:[url path]];
		NSString *textEncodingName = @"utf-8";
		NSString *path = [url path];
		NSError *error = nil;
		
		// first check to see if we're attempting to load a file from the 
		// filesystem and if so, and it exists, use that 
		if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			// per the Apple docs on what to do when you don't know the encoding ahead of a 
			// file read:
			// step 1: read and attempt to have system determine
			html = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
			if (html==nil && error!=nil)
			{
				//step 2: if unknown encoding, try UTF-8
				error = nil;
				html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
				if (html==nil && error!=nil)
				{
					//step 3: try an appropriate legacy encoding (if one) -- what's that? Latin-1?
					//at this point we're just going to fail
					NSLog(@"[ERROR] Couldn't determine the proper encoding. Make sure this file: %@ is UTF-8 encoded.",[path lastPathComponent]);
				}
				else
				{
					// if we get here, it succeeded using UTF8
					encoding = NSUTF8StringEncoding;
					textEncodingName = @"utf-8";
				}
			}
			else
			{
				error = nil;
				if (encoding == NSUTF8StringEncoding)
				{
					textEncodingName = @"utf-8";
				}
				else if (encoding == NSUTF16StringEncoding)
				{
					textEncodingName = @"utf-16";
				}
				else if (encoding == NSASCIIStringEncoding)
				{
					textEncodingName = @"us-ascii";
				}
				else if (encoding == NSISOLatin1StringEncoding)
				{
					textEncodingName = @"latin1";
				}
				else if (encoding == NSShiftJISStringEncoding)
				{
					textEncodingName = @"shift_jis";
				}
				else if (encoding == NSWindowsCP1252StringEncoding)
				{
					textEncodingName = @"windows-1251";
				}
				else 
				{
					NSLog(@"[WARN] I have no idea what the appropriate text encoding is for: %@. Please report this to Appcelerator support.",url);
				}
			}
			if (error!=nil && [error code]==261)
			{
				// this is a different encoding than specified, just send it to the webview to load
				[url retain];
				NSURLRequest *request = [NSURLRequest requestWithURL:url];
				[[self webview] loadRequest:request];
				if (scalingOverride==NO)
				{
					[[self webview] setScalesPageToFit:YES];
				}
				return;
			}
			else if (error!=nil)
			{
				NSLog(@"[ERROR] error loading file: %@. Message was: %@",path,error);
			}
		}
		else
		{
			// convert it into a app:// relative path to load the resource
			// from our application
			url = [self fileURLToAppURL:url];
			NSData *data = [TiUtils loadAppResource:url];
			if (data!=nil)
			{
				html = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
			}
		}
		if (html!=nil)
		{
			[self loadHTML:html encoding:encoding textEncodingName:textEncodingName mimeType:mimeType];
			[url retain];
		}
		else 
		{
			NSLog(@"[WARN] couldn't load URL: %@",url);
			url = nil; // not retained at this point so just release it
		}
	}
}

-(void)evalJS:(NSArray*)args
{
	NSString *code = [args objectAtIndex:0];
	NSString* result = [[self webview] stringByEvaluatingJavaScriptFromString:code];
	// write the result into our blob
	if ([args count] > 1 && result!=nil)
	{
		TiBlob *blob = [args objectAtIndex:1];
		[blob setData:[result dataUsingEncoding:NSUTF8StringEncoding]];
	}
}


-(CGFloat)autoHeightForWidth:(CGFloat)value
{
	CGRect oldBounds = [[self webview] bounds];
	[webview setBounds:CGRectMake(0, 0, value, 0)];
	CGFloat result = [[webview stringByEvaluatingJavaScriptFromString:@"document.height"] floatValue];
	[webview setBounds:oldBounds];
	return result;
}

#pragma mark WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	if ([self.proxy _hasListeners:@"beforeload"])
	{
		NSDictionary *event = url == nil ? nil : [NSDictionary dictionaryWithObject:[url absoluteString] forKey:@"url"];
		[self.proxy fireEvent:@"beforeload" withObject:event];
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	if (spinner!=nil)
	{
		[UIView beginAnimations:@"webspiny" context:nil];
		[UIView setAnimationDuration:0.3];
		[spinner removeFromSuperview];
		[UIView commitAnimations];
		[spinner autorelease];
		spinner = nil;
	}
	if ([self.proxy _hasListeners:@"load"])
	{
		NSDictionary *event = url == nil ? nil : [NSDictionary dictionaryWithObject:[url absoluteString] forKey:@"url"];
		[self.proxy fireEvent:@"load" withObject:event];
	}
	
	TiViewProxy * ourProxy = (TiViewProxy *)[self proxy];
	
	[ourProxy setNeedsRepositionIfAutoSized];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	if ([self.proxy _hasListeners:@"error"])
	{
		NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObject:[url absoluteString] forKey:@"url"];
		[event setObject:[error description] forKey:@"message"];
		[self.proxy fireEvent:@"error" withObject:event];
	}
}

#pragma mark TiEvaluator

- (TiHost*)host
{
	return [self.proxy _host];
}

- (void)evalFile:(NSString*)path
{
	NSURL *url_ = [path hasPrefix:@"file:"] ? [NSURL URLWithString:path] : [NSURL fileURLWithPath:path];
	
	if (![path hasPrefix:@"/"] && ![path hasPrefix:@"file:"])
	{
		NSURL *root = [[self host] baseURL];
		url_ = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",root,path]];
	}
	
	NSString *code = [NSString stringWithContentsOfURL:url_ encoding:NSUTF8StringEncoding error:nil];
	
	[self evalJS:[NSArray arrayWithObject:code]];
}

- (void)fireEvent:(id)listener withObject:(id)obj remove:(BOOL)yn thisObject:(id)thisObject_
{
	NSDictionary *event = (NSDictionary*)obj;
	NSString *name = [event objectForKey:@"type"];
	NSString *js = [NSString stringWithFormat:@"Ti.App._dispatchEvent('%@',%@,%@);",name,listener,[SBJSON stringify:event]];
	[[self webview] performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:js waitUntilDone:NO];
}

- (id)preloadForKey:(id)key
{
	return nil;
}

- (KrollContext*)krollContext
{
	return nil;
}

@end
