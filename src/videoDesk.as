package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;

	[SWF(width = "800", height = "800", backgroundColor = "#000000")]
	public class videoDesk extends Sprite
	{
		private var bs: FileReferenceList;
		private var pendingFiles: Array;
		private var loadImages: Array;
		
		private var tsD: TextField;
		private var tsW: TextField;
		private var tsH: TextField;
		
		private var previewBitmap: Bitmap; 

		public function videoDesk()
		{
			stage.scaleMode = StageScaleMode.EXACT_FIT;

			tsD = addText( 5, "duration" );
			tsW = addText( 30, "width" );
			tsH = addText( 55, "height" );
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, onKey );
		}
		
		private function onKey( e: KeyboardEvent ):void{
			if( e.keyCode == Keyboard.ENTER ){
				selectPictures();
			}
			else if( e.keyCode == Keyboard.S && e.controlKey ){
				saveTexture();
			}
			else if( e.keyCode == Keyboard.P && e.controlKey ){
				preview( true );
			}
		}
		
		private function selectPictures():void{
			var extensionName: String = "png";
			bs = new FileReferenceList();
			bs.browse( [new FileFilter( extensionName, "*." + extensionName )] );
			bs.addEventListener( Event.SELECT, onSelect );
		}

		protected function onSelect( e: Event ): void{
			var file: FileReference;
			pendingFiles = [];
			loadImages = [];
			for (var i: int = 0; i < bs.fileList.length; i++) {
				file = FileReference(bs.fileList[i]);
				addPendingFile(file);
			}
		}
		
		private function addPendingFile(file:FileReference):void {
			pendingFiles.push(file);
			file.addEventListener(Event.COMPLETE, completeHandler);
			file.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			file.load();
		}
		
		private function completeHandler( e: Event ):void{
			trace( e.target.name )
			try{
				var bit: ByteArray = (e.target as FileReference).data;
				var index: int = pendingFiles.indexOf(e.target);
				var ld: Loader = new Loader;
				ld.loadBytes( bit );
				loadImages[index] = ld;
			}
			catch( e ){
				trace( e );
			}
		}

		private function ioErrorHandler(event:Event):void {
			var file:FileReference = FileReference(event.target);
			trace("ioErrorHandler: name=" + file.name);
		}

		private function addText( y: int, text: String ):TextField {
			var tx: TextField = new TextField;
			tx.type = TextFieldType.INPUT;
			tx.y = y;
			tx.x = 5;
			tx.background = true;
			tx.backgroundColor = 0xFFFFFF;
			tx.textColor = 0;
			tx.width = 100;
			tx.height = 20;
			tx.restrict = "0-9\.";
			addChild( tx );

			var lb: TextField = new TextField;
			lb.y = y;
			lb.x = 115;
			lb.textColor = 0xFFFFFF;
			lb.text = text;
			addChild( lb );
			return tx;
		}
		
		private function preview( showOnStage: Boolean = false ): Point{
			if( !loadImages || loadImages.length == 0 ) return null;
			const wd: int = int( tsW.text );
			const ht: int = int( tsH.text );
			if( !wd || ! ht ) return null;
			const bitmapCount: int = loadImages.length;

			if( previewBitmap && contains( previewBitmap ) ){
				removeChild( previewBitmap );
			}
			
			var bitmapWidth: int = wd;
			var bitmapHeight: int = ht;
			var rowCount: int = 1;
			var colCount: int = 1;
			while( rowCount * colCount < bitmapCount ){
				if( bitmapHeight + ht <= bitmapWidth ){
					bitmapHeight += ht;
					colCount += 1;
				}
				else{
					bitmapWidth += wd;
					rowCount += 1;
				}
			}
			
			var bitmapData: BitmapData = new BitmapData( bitmapWidth, bitmapHeight, true, 0x00000000 );
			for( var i: int = 0; i < bitmapCount; i++ ){
				var bitmap: Loader = loadImages[i];
				var offsetX: int = i % rowCount * wd;
				var offsetY: int = Math.floor( i / rowCount ) * ht;
				bitmapData.draw( bitmap, new Matrix( 1, 0, 0, 1, offsetX, offsetY ), null, null, new Rectangle( offsetX, offsetY, wd, ht ) );
			}
			previewBitmap = new Bitmap(bitmapData);
			if( showOnStage )addChildAt( previewBitmap, 0 );
			
			return new Point( rowCount, colCount );
		}
		
		private function saveTexture(): void{
			const duration: int = Number( tsD.text );
			if( !duration ) return;
			var pt: Point = preview();
			if( !pt ) return;
			var rowCount: int = pt.x;
			const wd: int = int( tsW.text );
			const ht: int = int( tsH.text );
			var obj: Object = {}
			obj.duration = duration;
			obj.width = wd;
			obj.height = ht;
			obj.frames = [];
			for( var i: int; i < loadImages.length; i++  ){
				obj.frames[i] = { x: i % rowCount * wd, y: Math.floor( i / rowCount ) * ht };
			}
			var str: String = JSON.stringify( obj );
			var file: FileReference = new FileReference;
			file.save( str, "name.json" );
		}
	}
}