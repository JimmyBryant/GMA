package com.web
{
	import com.google.ads.ima.api.AdErrorEvent;
	import com.google.ads.ima.api.AdEvent;
	import com.google.ads.ima.api.AdsLoader;
	import com.google.ads.ima.api.AdsManager;
	import com.google.ads.ima.api.AdsManagerLoadedEvent;
	import com.google.ads.ima.api.AdsRenderingSettings;
	import com.google.ads.ima.api.AdsRequest;
	import com.google.ads.ima.api.ViewModes;
	
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	
	import mx.events.FlexEvent;
	
	import org.osmf.events.TimeEvent;
	
	import spark.components.Group;
	import spark.components.VideoPlayer;
	import spark.core.SpriteVisualElement;
	
	/**
	 * 简单的 Google IMA SDK 视频播放器集成。
	 */
	public class SdkIntegrationExample {
		
		private static const CONTENT_URL:String =
			"http://rmcdn.2mdn.net/Demo/vast_inspector/android.flv";
		
/*		private static const LINEAR_AD_TAG:String =
			"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
			"iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&impl=s&" +
			"gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&" +
			"url=[referrer_url]&correlator=[timestamp]&" +
			"cust_params=iab_vast_samples%3Dlinear";
		
		private static const NONLINEAR_AD_TAG:String =
			"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
			"iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&" +
			"impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&" +
			"url=[referrer_url]&correlator=[timestamp]&" +
			"cust_params=iab_vast_samples%3Dimageoverlay";*/
		private static const LINEAR_AD_TAG:String='http://googleads.g.doubleclick.net/pagead/ads?ad_type=video_text_image&client=ca-video-pub-0869844596169425&description_url=http%3A%2F%2Fwww.youku.com.%2F';		
		private static const NONLINEAR_AD_TAG:String='http://googleads.g.doubleclick.net/pagead/ads?ad_type=video_text_image&client=ca-video-pub-6344824857170504&description_url=http%3A%2F%2Fwww.youku.com.%2F';
		// 视频播放器对象。
		private var videoPlayer:VideoPlayer;
		private var fullScreenExited:Boolean;
		private var contentPlayheadTime:Number;
		
		// SDK 对象
		private var adsLoader:AdsLoader;
		private var adsManager:AdsManager;
		
		/**
		 * 设置用户广告和内容播放的点击播放播放器。
		 *
		 * @param videoPlayerValue 内容视频播放器。
		 */
		public function SdkIntegrationExample(videoPlayerValue:VideoPlayer):void {
			videoPlayer = videoPlayerValue;
			videoPlayer.source = CONTENT_URL;
			// 添加一些自定义事件处理程序。
			videoPlayer.stage.addEventListener(FullScreenEvent.FULL_SCREEN,
				fullscreenChangeHandler);
			videoPlayer.addEventListener(TimeEvent.COMPLETE, contentCompleteHandler);
			videoPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE,
				contentPlayheadTimeChangeHandler);
			// Flex 全屏问题解决办法：退出全屏时，
			// Flex 视频播放器组件仍然有旧的尺寸值。我们等待
			// 更新完整事件，随后，系统将提供正确的值。
			videoPlayer.addEventListener(FlexEvent.UPDATE_COMPLETE,
				videoPlayerUpdateCompleteHandler);
		}
		
		/**
		 * 用户点击“线性广告”单选按钮时使用的处理程序。
		 */
		public function linearAdSelectionHandler(event:Event):void {
			destroyAdsManager();
			requestAds(LINEAR_AD_TAG);
		}
		
		/**
		 * 用户点击“非线性广告”单选按钮时使用的处理程序。
		 */
		public function nonlinearAdSelectionHandler(event:Event):void {
			destroyAdsManager();
			requestAds(NONLINEAR_AD_TAG);
		}
		
		/**
		 * 使用指定广告代码请求广告。
		 *
		 * @param adTag 返回有效 VAST 响应的网址。
		 */
		private function requestAds(adTag:String):void {
			if (adsLoader == null) {
				// 第一次请求时创建 AdsLoader。
				adsLoader = new AdsLoader();
				adsLoader.addEventListener(AdsManagerLoadedEvent.ADS_MANAGER_LOADED,
					adsManagerLoadedHandler);
				adsLoader.addEventListener(AdErrorEvent.AD_ERROR, adsLoadErrorHandler);
			}
			
			// AdsRequest 封装了请求广告所需的所有属性。
			var adsRequest:AdsRequest = new AdsRequest();
			adsRequest.adTagUrl = adTag;
			adsRequest.linearAdSlotWidth = videoPlayer.width;
			adsRequest.linearAdSlotHeight = videoPlayer.height;
			adsRequest.nonLinearAdSlotWidth = videoPlayer.width;
			adsRequest.nonLinearAdSlotHeight = videoPlayer.height;
			
			// 指示 AdsLoader 使用 AdsRequest 对象请求广告。
			adsLoader.requestAds(adsRequest);
		}
		
		/**
		 * AdsLoader 成功抓取广告后调用。
		 */
		private function adsManagerLoadedHandler(event:AdsManagerLoadedEvent):void {
			// 发布商可通过该对象修改默认偏好设置。
			var adsRenderingSettings:AdsRenderingSettings =
				new AdsRenderingSettings();
			
			// 为了支持 VMAP 广告，广告管理器需要
			// 提供内容当前进度条位置的对象。
			var contentPlayhead:Object = {};
			contentPlayhead.time = function():Number {
				return contentPlayheadTime * 1000; // convert to milliseconds.
			};
			
			// 通过事件对象引用 AdsManager 对象。
			adsManager = event.getAdsManager(contentPlayhead, adsRenderingSettings);
			if (adsManager) {
				// Add required ads manager listeners.
				// 所有广告均播放完毕后，ALL_ADS_COMPLETED 事件将被触发。
				// 广告连播和 VMAP 时可能播放了多个广告。
				adsManager.addEventListener(AdEvent.ALL_ADS_COMPLETED,
					allAdsCompletedHandler);
				// 如果广告是线性广告，其将触发内容暂停请求事件。        
				adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED,
					contentPauseRequestedHandler);
				// 广告结束时或广告为非线性广告时，内容继续播放事件将
				// 触发。例如，如果 VMAP 响应只有后贴片广告，则系统将为
				// 后贴片广告（尚未展示）触发内容继续播放事件，以指示
				// 应开始播放或继续播放内容。
				adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED,
					contentResumeRequestedHandler);
				// 我们想知道广告何时开始。
				adsManager.addEventListener(AdEvent.STARTED, startedHandler);
				adsManager.addEventListener(AdErrorEvent.AD_ERROR,
					adsManagerPlayErrorHandler);
				
				// 如果您的视频播放器支持指定的 VPAID 广告版本，则在
				// 此版本中进行传递。如果您的视频播放器不支持 VPAID 广告，
				// 则只在 1.0 版本中进行传递。
				adsManager.handshakeVersion("1.0");
				// 为使 VMAP 广告正常工作，应先调用 Init，
				// 然后再播放内容。
				adsManager.init(videoPlayer.videoDisplay.width,
					videoPlayer.videoDisplay.height,
					ViewModes.NORMAL);
				
				// 将 adsContainer 添加到显示列表中。以下是关于如何
				// 使用 Flex 播放器显示的示例。
				var flexAdContainer:SpriteVisualElement = new SpriteVisualElement();
				flexAdContainer.addChild(adsManager.adsContainer);
				(videoPlayer.videoDisplay.parent as Group).addElement(flexAdContainer);
				
				// 开始播放广告。
				adsManager.start();
			}
		}
		
		/**
		 * 如果广告加载过程中发生错误，可恢复内容或
		 * 提出另一个广告请求。在此示例中，我们恢复了内容
		 * 如果加载广告时发生错误。
		 
		 */
		private function adsLoadErrorHandler(event:AdErrorEvent):void {
			trace("warning", "Ads load error: " + event.error.errorMessage);
			videoPlayer.play();
		}
		
		/**
		 * 广告管理器播放期间发生的错误应视为
		 * 信息性信号。如果没有其他要展示的广告，SDK 将发送
		 * 所有已完成广告的事件。
		 */
		private function adsManagerPlayErrorHandler(event:AdErrorEvent):void {
			trace("warning", "Ad playback error: " + event.error.errorMessage);
		}
		
		/**
		 * 无需使用 AdsManager 引用时，请将其清除。要阻止内存泄露，
		 * 必须执行明确清除。
		 */
		private function destroyAdsManager():void {
			enableContentControls();
			if (adsManager) {
				if (adsManager.adsContainer.parent &&
					adsManager.adsContainer.parent.contains(adsManager.adsContainer)) {
					adsManager.adsContainer.parent.removeChild(adsManager.adsContainer);
				}
				adsManager.destroy();
			}
		}
		
		/**
		 * 当 AdsManager 请求发布商暂停内容时，它会
		 * 引发此事件。
		 */
		private function contentPauseRequestedHandler(event:AdEvent):void {
			// 此广告将覆盖大部分内容，因此必须
			// 暂停内容。
			if (videoPlayer.playing) {
				videoPlayer.pause();
			}
			// 手动切换播放按钮状态。
			videoPlayer.playPauseButton.selected =
				!videoPlayer.playPauseButton.selected;
			// 重新连接控制器，以影响广告管理器，而不是内容视频。
			enableLinearAdControls();
			// 通常不允许取消广告。
			canScrub = false;
		}
		
		/**
		 * 当 AdsManager 请求发布商恢复内容时，它会
		 * 引发此事件。
		 */
		private function contentResumeRequestedHandler(event:AdEvent):void {
			// 重新连接控制器，以影响广告管理器，而不是内容视频。
			enableContentControls();
			videoPlayer.play();
		}
		
		/**
		 * 如果广告已开始，AdsManager 将引发此事件。
		 */
		private function startedHandler(event:AdEvent):void {
			// 如果广告已存在，且为非线性广告，则启动包含此广告的内容。
			if (event.ad != null && !event.ad.linear) {
				videoPlayer.play();
			}
		}
		
		/**
		 * 如果请求的所有广告均已播放，则 AdsManager 将引发
		 * 此事件。
		 */
		private function allAdsCompletedHandler(event:AdEvent):void {
			// 如果广告管理器的所有广告均已播放完毕，则可摧毁此广告管理器。
			destroyAdsManager();
		}
		
		/**
		 * 用户点击“播放/暂停”按钮时，视频播放器将引发
		 * 此事件。
		 */
		private function playPauseButtonHandler(event:MouseEvent):void {
			// 阻止视频播放器接收事件，因为它会对内容
			// 产生影响。
			event.stopImmediatePropagation();
			var paused:Boolean = !videoPlayer.playPauseButton.selected;
			if (paused) {
				adsManager.pause();
			} else {
				adsManager.resume();
			}
		}
		
		/**
		 * 切换视频播放器控制器，以控制视频广告。
		 */
		private function enableLinearAdControls():void {
			// 订阅优先级最高的
			// 播放器控制点击事件，以便我们可以在
			// VideoPlayer 实例处理此点击前对其进行处理。
			videoPlayer.playPauseButton.addEventListener(MouseEvent.CLICK,
				playPauseButtonHandler,
				false, // 使用抓取。
				int.MAX_VALUE);
			videoPlayer.volumeBar.addEventListener(Event.CHANGE,
				volumeChangeHandler,
				false, // 使用抓取。
				int.MAX_VALUE);
			videoPlayer.volumeBar.addEventListener(FlexEvent.MUTED_CHANGE,
				volumeMutedHandler,
				false,// 使用抓取。
				int.MAX_VALUE);
		}
		
		/**
		 * 切换视频播放器控制器，以控制视频广告。
		 */
		private function enableContentControls():void {
			videoPlayer.playPauseButton.removeEventListener(MouseEvent.CLICK,
				playPauseButtonHandler);
			videoPlayer.volumeBar.removeEventListener(Event.CHANGE,
				volumeChangeHandler);
			videoPlayer.volumeBar.removeEventListener(FlexEvent.MUTED_CHANGE,
				volumeMutedHandler);
			canScrub = true;
		}
		
		private function volumeMutedHandler(event:FlexEvent):void {
			// 阻止视频播放器接收事件，因为它会对内容
			// 产生影响。
			event.stopImmediatePropagation();
			adsManager.volume = 0;
		}
		
		private function volumeChangeHandler(event:Event):void {
			// 阻止视频播放器接收事件，因为它会对内容
			// 产生影响。
			event.stopImmediatePropagation();
			adsManager.volume = videoPlayer.volumeBar.value;
		}
		
		private function set canScrub(value:Boolean):void {
			videoPlayer.scrubBar.enabled = value;
			videoPlayer.scrubBar.mouseEnabled = value;
		}
		
		/**
		 * 更新 AdsManager 的进度条指针时间。
		 */
		private function contentPlayheadTimeChangeHandler(event:TimeEvent):void {
			contentPlayheadTime = event.time;
		}
		
		private function fullscreenChangeHandler(event:FullScreenEvent):void {
			if (event.fullScreen) {
				adsManager.resize(videoPlayer.videoDisplay.width,
					videoPlayer.videoDisplay.height,
					ViewModes.FULLSCREEN);
			} else {
				fullScreenExited = true;
				// 更新完成后，系统将调整广告管理器的大小。
			}
		}
		
		/**
		 * 视频播放器全屏功能调试解决办法。
		 */
		private function videoPlayerUpdateCompleteHandler(event:FlexEvent):void {
			if (fullScreenExited) {
				fullScreenExited = false;
				adsManager.resize(videoPlayer.videoDisplay.width,
					videoPlayer.videoDisplay.height,
					ViewModes.NORMAL);
			}
		}
		
		/**
		 * 内容播放完毕后，视频播放器将引发此事件。
		 */
		private function contentCompleteHandler(event:TimeEvent):void {
			videoPlayer.stage.removeEventListener(FullScreenEvent.FULL_SCREEN,
				fullscreenChangeHandler);
			videoPlayer.removeEventListener(FlexEvent.UPDATE_COMPLETE,
				videoPlayerUpdateCompleteHandler);
			videoPlayer.removeEventListener(TimeEvent.COMPLETE,
				contentCompleteHandler);
			// 任何内容结束后，即通知 SDK，即使此内容不包含广告。
			// SDK 使用这种方法效果更好地选择广告（尤其是VMAP）。
			adsLoader.contentComplete();
		}
	}
}