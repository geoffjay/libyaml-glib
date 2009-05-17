using YAML;
namespace GLib.YAML {
	public class Node {
		public NodeType type;
		public string tag;
		public Mark start_mark;
		public Mark end_mark;
		public string anchor;
		public class Alias:Node {
			public string alias;
		}
		public class Scalar:Node {
			public string value;
			public ScalarStyle style;
		}
		public class Sequence:Node {
			public List<Node> items;
			public SequenceStyle style;
		}
		public class Mapping:Node {
			public HashTable<Node, Node> pairs 
			= new HashTable<Node, Node>(direct_hash, direct_equal);
			public HashTable<Node, Node> pairs_reverted
			= new HashTable<Node, Node>(direct_hash, direct_equal);
			public MappingStyle style;
		}
	}
	public class Document {
		public List<Node> nodes;
		public Mark start_mark;
		public Mark end_mark;
		public HashTable<string, Node> anchors
		= new HashTable<string, Node>(str_hash, str_equal);
		public Document.load(ref Parser parser) {
			Loader loader = new Loader();
			loader.load(ref parser, this);
		}
	}
	internal class Loader {
		public Loader() {}
		private Document document;
		public bool load(ref Parser parser, Document document) {
			this.document = document;
			Event event;
			/* Look for a StreamStart */
			if(!parser.stream_start_produced) {
				return_val_if_fail(parser.parse(out event), false);
				assert(event.type == EventType.STREAM_START_EVENT);
			}
			return_val_if_fail (!parser.stream_end_produced, true);

			return_val_if_fail (parser.parse(out event), false);
			/* if a StreamEnd seen, return OK */
			return_val_if_fail (event.type != EventType.STREAM_END_EVENT, true);

			/* expecting a DocumentStart otherwise */
			assert(event.type == EventType.DOCUMENT_START_EVENT);
			document.start_mark = event.start_mark;

			return_val_if_fail (parser.parse(out event), false);
			/* Load the first node. 
			 * load_node with recursively load other nodes */
			return_val_if_fail (load_node(ref parser, ref event)!=null, false);
			
			/* expecting for a DocumentEnd */
			return_val_if_fail (parser.parse(out event), false);
			assert(event.type == EventType.DOCUMENT_END_EVENT);
			document.end_mark = event.end_mark;
			
			/* preserve the document order */
			document.nodes.reverse();
			return true;
		}
		public Node load_node(ref Parser parser, ref Event last_event) {
			switch(last_event.type) {
				case EventType.ALIAS_EVENT:
					return load_alias(ref parser, ref last_event);
				case EventType.SCALAR_EVENT:
					return load_scalar(ref parser, ref last_event);
				case EventType.SEQUENCE_START_EVENT:
					return load_sequence(ref parser, ref last_event);
				case EventType.MAPPING_START_EVENT:
					return load_mapping(ref parser, ref last_event);
				default:
					assert_not_reached();
			}
		}
		public Node? load_alias(ref Parser parser, ref Event last_event) {
			assert_not_reached();
			return null;
		}
		private static string normalize_tag(string? tag, string @default) {
			if(tag == null || tag == "!") {
				return @default;
			}
			return tag;
		}
		public Node? load_scalar(ref Parser parser, ref Event event) {
			Node.Scalar node = new Node.Scalar();
			node.anchor = event.data.scalar.anchor;
			node.tag = normalize_tag(event.data.scalar.tag,
					DEFAULT_SCALAR_TAG);
			node.value = event.data.scalar.value;
			node.style = event.data.scalar.style;
			node.start_mark = event.start_mark;
			node.end_mark = event.end_mark;

			/* Push the node to the document stack
			 * and register the anchor */
			document.nodes.prepend(node);
			if(node.anchor != null)
				document.anchors.insert(node.anchor, node);
			return node;
		}
		public Node? load_sequence(ref Parser parser, ref Event event) {
			Node.Sequence node = new Node.Sequence();
			node.anchor = event.data.sequence_start.anchor;
			node.tag = normalize_tag(event.data.sequence_start.tag,
					DEFAULT_SEQUENCE_TAG);
			node.style = event.data.sequence_start.style;
			node.start_mark = event.start_mark;
			node.end_mark = event.end_mark;

			/* Push the node to the document stack
			 * and register the anchor */
			document.nodes.prepend(node);
			if(node.anchor != null)
				document.anchors.insert(node.anchor, node);

			/* Load the items in the sequence */
			return_val_if_fail (parser.parse(out event), null);
			while(event.type != EventType.SEQUENCE_END_EVENT) {
				Node item = load_node(ref parser, ref event);
				/* prepend is faster than append */
				node.items.prepend(item);
				return_val_if_fail (parser.parse(out event), null);
			}
			/* Preserve the document order */
			node.items.reverse();

			/* move the end mark of the mapping
			 * to the END_SEQUENCE_EVENT */
			node.end_mark = event.end_mark;
			return node;
		}
		public Node? load_mapping(ref Parser parser, ref Event event) {
			Node.Mapping node = new Node.Mapping();
			node.tag = normalize_tag(event.data.mapping_start.tag,
					DEFAULT_MAPPING_TAG);
			node.anchor = event.data.mapping_start.anchor;
			node.style = event.data.mapping_start.style;
			node.start_mark = event.start_mark;
			node.end_mark = event.end_mark;

			/* Push the node to the document stack
			 * and register the anchor */
			document.nodes.prepend(node);
			if(node.anchor != null)
				document.anchors.insert(node.anchor, node);

			/* Load the items in the mapping */
			return_val_if_fail (parser.parse(out event), null);
			while(event.type != EventType.MAPPING_END_EVENT) {
				Node key = load_node(ref parser, ref event);
				return_val_if_fail(key!=null, null);
				return_val_if_fail (parser.parse(out event), null);
				Node value = load_node(ref parser, ref event);
				return_val_if_fail(value!=null, null);
				node.pairs.insert(key, value);
				node.pairs_reverted.insert(value, key);
				return_val_if_fail (parser.parse(out event), null);
			}
			/* move the end mark of the mapping
			 * to the END_MAPPING_EVENT */
			node.end_mark = event.end_mark;
			return node;
		}
	}

}