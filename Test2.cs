using Godot;
using System;

public class Test2 : Sprite {
	static vertex[] points = new vertex[Hackenbush.MAXNODES];
	public Hackenbush logic = new Hackenbush();
	
	public Hackenbush.game G = new Hackenbush.game(128 * 4);
	
	public struct vertex {
		int x, y;
		int selected;
		public int ground;
		public int index; // might be zero, if grounded
		int display; // 1 to display it; 0 otherwise
	}

	struct line {
		public int p, q;
		public int color;
		public int selected;
		public int gindex; // index used in game-playing code
		public int reddupcount; // number of red copies of this line
		public int bluedupcount; // number of blue copies of this line
		public int isbezier;
		public int x1, y1, x2, y2; // coords of control points: order = p, (x1, y1), (x2, y2), q
	}

	public int makegame() {
		line line1 = new line{};
		line1.p = 0;
		line1.q = 1;
		line1.color = 1;
		line line2 = new line{};
		line2.p = 1;
		line2.q = 2;
		line2.color = 2;
		line line3 = new line{};
		line3.p = 2;
		line3.q = 3;
		line3.color = 1;
		line line4 = new line{};
		line4.p = 4;
		line4.q = 5;
		line4.color = 2;
		line line5 = new line{};
		line5.p = 5;
		line5.q = 6;
		line5.color = 1;
		
		line[] lines = new line[] {line1, line2, line3, line4, line5};
		
		vertex point1 = new vertex{};
		vertex point2 = new vertex{};
		vertex point3 = new vertex{};
		vertex point4 = new vertex{};
		vertex point5 = new vertex{};
		vertex point6 = new vertex{};
		vertex point7 = new vertex{};
		point1.ground = 0;
		point2.ground = 2;
		point3.ground = 2;
		point4.ground = 2;
		point5.ground = 0;
		point6.ground = 2;
		point7.ground = 2;
		points = new vertex[]{point1, point2, point3, point4, point5, point6, point7};
		
		Hackenbush.edgecount = 0;
		Hackenbush.pointcount = points.Length;
		
		int i, j, n1 = 0, n2 = 0;
		
		j = 1;
		for (i = 0; i < Hackenbush.pointcount; i++) {
			if (points[i].ground == 0) points[i].index = 0; else points[i].index = j++;
		}
		
		// gamelinecount = linecount;
		
		
		for (i = 0; i < Hackenbush.MAXNODES; i++) {
			Hackenbush.node[i, 0] = -1;
		}
		
		j = 0;
		while (j < lines.Length) { // DEBUG < linecount
			n1 = points[lines[j].p].index;
			n2 = points[lines[j].q].index;
			if (n1 > n2) { // guarantees they're in order
				int temp = n1;
				n1 = n2;
				n2 = temp;
			}
			
			G.edge[Hackenbush.edgecount * 4 + 0] = n1;
			G.edge[Hackenbush.edgecount * 4 + 1] = n2;
			G.edge[Hackenbush.edgecount * 4 + 2] = lines[j++].color;
			
			
			i = 0;
			while (Hackenbush.node[n1, i] != -1) i++;
			Hackenbush.node[n1, i++] = Hackenbush.edgecount;
			Hackenbush.node[n1, i] = -1;
			
			if (n1 != n2) {
				i = 0;
				while (Hackenbush.node[n2, i] != -1) i++;
				
				Hackenbush.node[n2, i++] = Hackenbush.edgecount;
				Hackenbush.node[n2, i] = -1;
			}
			Hackenbush.edgecount++;
		}
		
		G.edge[Hackenbush.edgecount * 4 + 0] = G.edge[Hackenbush.edgecount * 4 + 1] = -1;
		return 1;
	}
	
	public override void _Ready() {
		makegame();
		
		Hackenbush.cutedge(1, G);
		
		GD.Print(Hackenbush.isemptygame(G));
		Hackenbush.surreal s = Hackenbush.calcgamevalue(G);
		GD.Print("Game Value: ",  Hackenbush.calcgamevalue(G).num, " / ", Hackenbush.calcgamevalue(G).den);
		
		Hackenbush.findbestgamemoves(G);
		GD.Print("Best Move Red: ",  Hackenbush.Bestred, ", Best Move Blue: ", Hackenbush.Bestblue);
	}
}
