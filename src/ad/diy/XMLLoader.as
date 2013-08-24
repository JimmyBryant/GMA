package ad.diy{
	
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	public class XMLLoader extends Sprite{
			  
		private var urlLoader:URLLoader;
		private var XMLDoc:XML=null;
		
		public var xmlUrl:String;
		public function XMLLoader(url:String){
			xmlUrl=url;
		}
		/**
		 *	设置XMLDoc属性 
		 * @param value
		 * 
		 */		
		public function set XMLDocs(value:XML):void{
		
			XMLDoc=value;
		}
		/**
		 *	获取XMLDoc属性 
		 * @return 
		 * 
		 */		
		public function get XMLDocs():XML{			
			return XMLDoc;
		}
		/**
		 * load xml 
		 */
		public function load():void{
			
			urlLoader=new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE,XMLCompeleteHandler);
			urlLoader.addEventListener(ErrorEvent.ERROR,XMLErrorHandler);
			urlLoader.load(new URLRequest(xmlUrl));
		}
		
		
		/**
		 * xml文档加载成功的回调函数
		 */	
		private function XMLCompeleteHandler(event:Event):void{			
			var xml:XML =XML(urlLoader.data);
			XMLDocs=xml;
			this.dispatchEvent(new Event(XMLEvent.Loaded));
		}
		/**
		 * xml文档加载错误回调函数 
		 */
		private function XMLErrorHandler(event:ErrorEvent):void{
			this.dispatchEvent(new Event(XMLEvent.Error));
		}
	}

}