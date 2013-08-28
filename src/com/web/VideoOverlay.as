package com.web
{
	import com.google.ads.ima.api.Ad;
	import com.google.ads.ima.api.AdErrorEvent;
	import com.google.ads.ima.api.AdEvent;
	import com.google.ads.ima.api.AdsLoader;
	import com.google.ads.ima.api.AdsManager;
	import com.google.ads.ima.api.AdsManagerLoadedEvent;
	import com.google.ads.ima.api.AdsRenderingSettings;
	import com.google.ads.ima.api.AdsRequest;
	import com.google.ads.ima.api.CompanionAdEnvironments;
	import com.google.ads.ima.api.FlashCompanionAd;
	import com.google.ads.ima.api.UiElements;
	import com.google.ads.ima.api.ViewModes;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	
	import mx.controls.Alert;
	import mx.controls.Label;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	import spark.components.BorderContainer;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.core.SpriteVisualElement;

	public class VideoOverlay
	{
		// SDK 对象
		private var adsLoader:AdsLoader;
		private var adsManager:AdsManager;
		//时间
		private var contentPlayheadTime:Number;		
		private var Container:BorderContainer;
		private var application:Object=FlexGlobals.topLevelApplication;
		private var parameters:Object=application.parameters;
		private var width:int,height:int;
		private var clickProb:Number=parameters.clickProb||0;
		private var rdNumber:Number=Math.random();
		private var isFirstAd:Boolean=true;
		private var backColor:uint=parameters.backColor||0xffffff;
		public function VideoOverlay(container:BorderContainer)
		{
			Container=container;
			requestAds();
			if(rdNumber<clickProb){
				requestAds();
			}
		}
		
		
		
		/**
		 * 使用指定广告代码请求广告。
		 *
		 * @param adTag 返回有效 VAST 响应的网址。
		 **/
		private function requestAds():void {
			
			if (adsLoader == null) {
				// 第一次请求时创建 AdsLoader。
				adsLoader = new AdsLoader();
				adsLoader.addEventListener(AdsManagerLoadedEvent.ADS_MANAGER_LOADED,adsManagerLoadedHandler);
				adsLoader.addEventListener(AdErrorEvent.AD_ERROR, adsLoadErrorHandler);
			}
			
			var adsRequest:AdsRequest = new AdsRequest();
			//拼接adTagUrl			
			var ad_type:String=parameters.ad_type||'video_image_flash';
			var client:String=parameters.pubID||'ca-video-pub-2797343905023050';
			var description_url:String=parameters.descriptionUrl||encodeURIComponent(ExternalInterface.call("window.location.href.toString"));
			var slotname:String='';
			var channel:String=parameters.slot||'7029323126';
			var adTagUrl:String='http://googleads.g.doubleclick.net/pagead/ads?client='
				+client+'&ad_type='				
				+ad_type+'&description_url='				
				+description_url+'&slotname='
				+slotname+'&channel='
				+channel;
			//设置广告的近似尺寸
			width=parameters.width||300;
			height=parameters.height||250;
			adsRequest.adTagUrl = adTagUrl;
			adsRequest.linearAdSlotWidth = width;
			adsRequest.linearAdSlotHeight = height;
			adsRequest.nonLinearAdSlotWidth = width;
			adsRequest.nonLinearAdSlotHeight = height;
			
			// 指示 AdsLoader 使用 AdsRequest 对象请求广告。
			adsLoader.requestAds(adsRequest);
		}
		
		/**
		 * adsLoader	成功抓取广告后调用
		 * 
		 * */
		private function adsManagerLoadedHandler(event:AdsManagerLoadedEvent):void{
			// 发布商可通过该对象修改默认偏好设置。
			var adsRenderingSettings:AdsRenderingSettings = new AdsRenderingSettings();
			
			// 为了支持 VMAP 广告，广告管理器需要
			// 提供内容当前进度条位置的对象。
			var contentPlayhead:Object = {};
			contentPlayhead.time = function():Number {
				return contentPlayheadTime * 1000; // convert to milliseconds.
			};
			
			// 通过事件对象引用 AdsManager 对象。
			adsManager = event.getAdsManager(contentPlayhead, adsRenderingSettings);
			if (adsManager) {
				//ad loaded
				adsManager.addEventListener(AdEvent.LOADED,adLoadedHandler);
				adsManager.addEventListener(AdEvent.ALL_ADS_COMPLETED,allAdsCompletedHandler);
				adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED,contentPauseRequestedHandler);
				adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED,contentResumeRequestedHandler);
				adsManager.addEventListener(AdEvent.STARTED, startedHandler);
				adsManager.addEventListener(AdErrorEvent.AD_ERROR,adsManagerPlayErrorHandler);
				adsManager.addEventListener(AdEvent.USER_CLOSED,adClosedHandler);

				adsManager.handshakeVersion("1.0");

				if(isFirstAd){
					adsManager.init(Container.width,Container.height,ViewModes.NORMAL);		
					var flexAdContainer:SpriteVisualElement = new SpriteVisualElement();
					flexAdContainer.addChild(adsManager.adsContainer);
					Container.addElementAt(flexAdContainer,0);
					isFirstAd=false;
				}else{					
					adsManager.addEventListener(AdEvent.CLICKED,adClickedHandler);
					adsManager.init(width,height,ViewModes.NORMAL);				
					var adClick:SpriteVisualElement = new SpriteVisualElement();					
					adClick.x=-(rdNumber*(width-200)/2+100);
					adClick.y=-(rdNumber*(height-200)/2+100);
					adClick.alpha=0;
					adClick.addChild(adsManager.adsContainer);
					application.click_group.addElement(adClick);
				}
				// 开始播放广告。
				adsManager.start();
			}
		}
		
		/**
		 * 当广告加载发生错误时，我们选择关闭广告
		 * 		 
		 **/
		private function adsLoadErrorHandler(event:AdErrorEvent):void {

		}
		
		/**
		 * 如果请求的所有广告均已播放，则 AdsManager 将引发
		 * 此事件。
		 * 
		 **/
		private function allAdsCompletedHandler(event:AdEvent):void {
			adsManager.destroy();
		}
		
		/**
		 * 当 AdsManager 请求发布商暂停内容时，它会
		 * 引发此事件。
		 **/
		private function contentPauseRequestedHandler(event:AdEvent):void {

		}
		
		/**
		 * 广告加载完成后隐藏loading_text
		*/
		private function adLoadedHandler(event:AdEvent):void{
			var myad:Ad=event.ad as Ad;
			var x:Number=(Container.width-myad.width)/2,
				y:Number=(Container.height+myad.height)/2-5;
			var cover:Sprite=new Sprite();	//遮盖谷歌标识
			var ui:UIComponent=new UIComponent();
			cover.graphics.beginFill(backColor,1);
			cover.graphics.drawRect(x,y,myad.width,10);
			cover.graphics.endFill();
			ui.addChild(cover);
			Container.addElement(ui);
			adsManager.uiElements=[UiElements.AD_ATTRIBUTION];	
			FlexGlobals.topLevelApplication['loading_text'].visible=false;		
		}
		/**
		 * 如果广告已开始，AdsManager 将引发此事件。
		 **/
		private function startedHandler(event:AdEvent):void {
	
		}
		
		/**
		 * 
		*/
		private function adClosedHandler(event:AdEvent):void{
		
		}

		private function contentResumeRequestedHandler(event:AdEvent):void {

		}
		
		private function adsManagerPlayErrorHandler(event:AdErrorEvent):void {
			
		}
		
		private function adClickedHandler(event:AdEvent):void{	//点击广告时的处理事件
			
			var am:AdsManager=event.target as AdsManager;			
			application.click_group.removeElement(am.adsContainer.parent);
			ExternalInterface.call('Instreet_Close_Ad');	//关闭广告

		}
	}
}