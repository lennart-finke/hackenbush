using Godot;
using System;

public class Hackenbush : Node {
	public static int MAXNODES = 128;
	public int MAXEDGESPERNODE =  64;
	public static int MAXEDGES = 64;
	static int HASHTABLESIZE =  1157007;
	static int HACKRED = 2;
	static int HACKBLUE = 1;
	
	public static int edgecount = 0;
	public static int pointcount = 0;
	
	public static int Bestred, Bestblue;
	
	static int hashcounter = 0;
	static int uniformplay = 0; // if 0, play equally-good moves at random
	
	surreal Value;
	
	public struct game {
		public int[] edge;
		
		public game(int size) {
			edge = new int[size];
		}
		
		public game(game g) {
			int length = g.edge.Length;
			edge = new int[length + 1];
			for (int i = 0; i < length; i++) {
				edge[i] = g.edge[i];
			}
		}
	}
	
	public struct surreal {
		public long den {get;set;}
		public long num {get;set;}
		
		public surreal(surreal s) {
			den = s.den;
			num = s.num;
		}
	}
	
	public static int[,] node = new int[128, 64];
	public static int[] mark = new int[128];
	public static int[,] componentlist = new int[MAXEDGES, MAXEDGES];
	public static surreal[] componentvalues = new surreal[MAXEDGES];
	
	struct gamevalue {
		long game {get;set;}
		surreal value {get;set;}
		int mark {get;set;}
	}
	
	unsafe struct hashentry {
		hashentry *next;
		gamevalue gv;
	};
	
	public static long getgamevalue(game g) {
		int i=0;
		long gv = 0;
		while (g.edge[i * 4 + 0] != -1) {
			gv <<= 1;
			if (g.edge[i * 4 + 0] >= 0)
				gv |= 1;
			i++;
		}
		return gv;
	}
	
	static int hashvalue(long x) {
		return (int)(x % HASHTABLESIZE);
	}
	
	 static bool surlessthan(surreal a, surreal b) { // safer relative to overflow
			long an, ad, bn, bd, f;
			
			an = a.num; ad = a.den; bn = b.num; bd = b.den;
			if (ad < bd) {
				f = bd/ad;
				return (an*f < bn);
			} else {
				f = ad/bd;
				return (an < bn*f);
			}
	}
	
	public static surreal reduce(surreal ain) {
			surreal a = new surreal(ain);
			long n = a.num, d = a.den;
			if (n < 0) {
				n = -n;
				while (((n&1) == 0) && ((d&1) == 0)) {
					n >>= 1; d >>= 1;
				}
				a.num = -n;
				a.den = d;
				return a;
			}
			while (((n&1) == 0) && ((d&1) == 0)) {
				n >>= 1; d >>= 1;
			}
			
			a.num = n;
			a.den = d;
			
			return a;
	}
	
	 static surreal surrealsum(surreal a, surreal b) {
		surreal aplusb = new surreal();
		long f;

		if (a.den < b.den) {
			f = b.den/a.den;
			a.num *= f;
			a.den *= f;
		} else if (a.den > b.den) {
			f = a.den/b.den;
			b.num *= f;
			b.den *= f;
		}
		aplusb.num = a.num + b.num;
		aplusb.den = b.den;
		aplusb = reduce(aplusb);
		return aplusb;
	}

	 static surreal surmiddle(surreal a, surreal b) { // a < b
		long f, d, nextnum;
		surreal alocal = new surreal(a);
		surreal blocal = new surreal(b);
		surreal surmid = new surreal();
		
		bool swap = false;

		if (a.num < 0 && b.num > 0) {
			surmid.num = 0;
			surmid.den = 1;
			return surmid;
		}
		if (b.num < 0 || a.num < 0) { // swap
			surreal tmp;
			tmp = alocal;
			alocal = blocal;
			blocal = tmp;
			swap = true;
			alocal.num *= -1;
			blocal.num *= -1;
		}
		// get the same denominator:
		if (alocal.den < blocal.den) {
			f = blocal.den/alocal.den;
			alocal.den *= f;
			alocal.num *= f;
		} else {
			f = alocal.den/blocal.den;
			blocal.den *= f;
			blocal.num *= f;
		}
		d = alocal.den; // d is common denominator
		if (alocal.num + 1 == blocal.num) {
			surmid.num = alocal.num + blocal.num;
			surmid.den = 2*d;
			if (swap) { // swap back
				surmid.num *= -1;
			}

			return surmid;
		}
		while (true) {
			nextnum = ((alocal.num + d)/d)*d;
			if (nextnum < blocal.num) {
				surmid.num = nextnum;
				surmid.den = alocal.den;
				surmid = reduce(surmid);
				if (swap) { // swap back
					surmid.num *= -1;
				}

				return surmid;
			}
			d = d/2;
		}
	}
	
	 static bool isgrounded(int e, game g, int initialcall) {
		int i, n0, n1;

		if (initialcall == 1) {
			i = 0;
			while (node[i, 0] != -1) mark[i++] = 0;
		}
		if ((n0 = g.edge[e * 4 + 0]) == 0 || (n1 = g.edge[e * 4 + 1]) == 0) return true;
		if (n0 == -2) return false;
		if (mark[n0] == 0) {
			mark[n0] = 1;
			i = 0;
			while (node[n0, i] != -1)
				if (isgrounded(node[n0, i++], g, 0)) return true;
		}
		if (mark[n1] == 0) {
			mark[n1] = 1;
			i = 0;
			while (node[n1, i] != -1)
				if (isgrounded(node[n1, i++], g, 0)) return true;
		}
		return false;
	}
	
	 static bool isbluegrounded(int e, game g, int initialcall) {
		int i, n0, n1;

		if (initialcall == 1) {
			i = 0;
			while (node[i, 0] != -1) mark[i++] = 0;
		}
		if ((n0 = g.edge[e * 4 + 0]) == 0 || (n1 = g.edge[e * 4 + 1]) == 0) return true;
		if (n0 == -2) return false;
		if (mark[n0] == 0) {
			mark[n0] = 1;
			i = 0;
			while (node[n0, i] != -1) {
				if (g.edge[node[n0, i] * 4 + 2] != HACKBLUE) i++;
				else if (isbluegrounded(node[n0, i++], g, 0)) return true;
			}
		}
		if (mark[n1] == 0) {
			mark[n1] = 1;
			i = 0;
			while (node[n1, i] != -1) {
				if (g.edge[node[n1, i] * 4 + 2] != HACKBLUE) i++;
				else if (isbluegrounded(node[n1, i++], g, 0)) return true;
			}
		}
		return false;
	}

	public static void markedges(game g, int nodenum) {
		int i = 0, e;
		while ((e = node[nodenum, i]) != -1) {
			if (g.edge[e * 4 + 3] == 0 && g.edge[e * 4 + 0] != -2) {
				g.edge[e * 4 + 3] = 1; // mark it
				markedges(g, g.edge[e * 4 + 0]);
				markedges(g, g.edge[e * 4 + 1]);
			}
			i++;
		}
	}
	
	public static void prunegame(game g) {
			int i;
			
			for (i = 0; i < edgecount; i++)  {
				g.edge[i * 4 + 3] = 0; // not looked at yet
			}
			
			markedges(g, 0); // mark edges connected to node 0
			for (i = 0; i < edgecount; i++)
				if (g.edge[i * 4 + 3] == 0)
					g.edge[i * 4 + 0] = -2;
	}

	public static bool isemptygame(game g) {
			int i = 0;
			
			while (g.edge[i * 4 + 0] != -1)
				if (g.edge[i++ * 4 + 0] >= 0) return false;
			return true;
	}
	
	public static int findcomponents(game g){
		int i, j, k, n1, n2, componentcount = 0, changed;
		game G = new game(g);
		int[] nodes = new int[MAXNODES];
		
		for (i = 0; i < MAXEDGES; i++)
			for (j = 0; j < MAXEDGES; j++)
				componentlist[i, j] = 0;
		
		i = 0;
		while (isemptygame(G) == false) {
			for (i = 0; i < MAXNODES; i++) nodes[i] = 0;
			i = 0;
			
			// Marks the first non-deleted edge, if not connected to the ground.
			while (G.edge[i * 4 + 0] == -2) i++;
			if (G.edge[i * 4 + 0] != 0) nodes[G.edge[i * 4 + 0]] = 1;
			if (G.edge[i * 4 + 1] != 0) nodes[G.edge[i * 4 + 1]] = 1;
			do {
				changed = 0;
				
				for (j = 1; j < MAXNODES; j++) {
					if (nodes[j] == 1) {
						k = 0;
						while (node[j, k] != -1) {
							n1 = G.edge[node[j, k] * 4 + 0];
							n2 = G.edge[node[j, k] * 4 + 1];
							if (n1 > 0 && nodes[n1] == 0) {
								nodes[n1] = 1;
								changed = 1;
							}
							if (n1 > 0 && n2 > 0 && nodes[n2] == 0) {
								nodes[n2] = 1;
								changed = 1;
							}
							k++;
						}
					}
				}
			} while (changed == 1);
			
			for (j = 1; j < MAXNODES; j++) {
				if (nodes[j] == 1) {
					for (k = 0; k < edgecount; k++) {
						if (G.edge[k * 4 + 0] == j || G.edge[k * 4 + 1] == j) {
							componentlist[componentcount, k] = 1;
							G.edge[k * 4 + 0] = -2;
						}
					}
				}
			}
			componentcount++;
		}
		
		return componentcount;
	}
	
	public int sanitycheckgame(game g) {
		int i;
		
		i = 0;
		while (g.edge[i * 4 + 0] != -1) {
			if (g.edge[i * 4 + 0] < 0 || g.edge[i * 4 + 0] >= MAXEDGES) return 0;
			if (g.edge[i * 4 + 1] < 0 || g.edge[i * 4 + 1] >= MAXEDGES) return 0;
			i++;
		}
		i = 0;
		while (g.edge[i * 4 + 0] != -1)
			if (isgrounded(i++, g, 1) == false) return 0;
		return 1;
	}

	public static void cutedge(int e, game g) {
		g.edge[e * 4 + 0] = -2;
		prunegame(g);
		return;
	}
	
	public static surreal componentvalue(game g, int firsttime) {
		surreal bluemax = new surreal();
		surreal redmin = new surreal();
		surreal newvalue = new surreal();
		game newg;
		int i;
		
		// DEBUG
		// Not really sure what this does...
		//doabortcheck();
		
		// TODO
		// maybe we already did it?
		// long gv = 0;
		// if (lookupgamevalue(gv = getgamevalue(g), value)) return;

		bluemax.den = -1; // illegal
		redmin.den = -1; // illegal
		bluemax.num = redmin.num = 0; // for lint's sake

		i = 0;
		while (g.edge[i * 4 + 0] != -1) {
			if (g.edge[i * 4 + 0] >= 0) {
				newg = new game(g);
				cutedge(i, newg);
				newvalue = componentvalue(newg, 0);
				switch (g.edge[i * 4 + 2]) {
					case 1: // HACKBLUE
						if (bluemax.den == -1) {
							bluemax = newvalue;
						} else if (surlessthan(bluemax, newvalue)) {
							bluemax = newvalue;
						}
						break;
					case 2: // HACKRED
						if (redmin.den == -1) {
							redmin = newvalue;
						} else if (surlessthan(newvalue, redmin)) {
							redmin = newvalue;
						}
						break;
					default:
						GD.Print("Component error!\n");
						break;
				}
			}
			i++;
		}
		if (bluemax.den == -1) {
			bluemax.den = 1;
			bluemax.num = -10000;
		}
		if (redmin.den == -1) {
			redmin.den = 1;
			redmin.num = 10000;
		}
		
		return surmiddle(bluemax, redmin);
		
		// TODO Hashmap
		// addgamevalue(gv, value);
	}
	
	 public static surreal calcgamevalue(game g) {
		int componentcount, i, j;
		game G;
		surreal locvalue = new surreal();

		componentcount = findcomponents(g);
		for (i = 0; i < componentcount; i++) {
			G = new game(g);
			//inithashtable(0);
			
			j = 0;
			while(G.edge[j * 4 + 0] != -1) {
				if (componentlist[i, j] == 0)
					G.edge[j * 4 + 0] = -2;
				j++;
			}
			locvalue = componentvalue(G, 1);
			componentvalues[i] = locvalue;
		}
		
		locvalue.num = 0;
		locvalue.den = 1;
		
		for (i = 0; i < componentcount; i++) {
			locvalue = surrealsum(locvalue, componentvalues[i]);
		}
			
		return locvalue;
	}
	
	public static void findbestgamemoves(game g) {
		surreal bluemax = new surreal();
		surreal redmin = new surreal();
		surreal newvalue;
		
		game newg;
		int i;
		int[] bestred = new int[100];
		int[] bestblue = new int[100];
		
		int brcnt = 0, bbcnt = 0;
		
		Bestred = Bestblue = -1;

		redmin.num = bluemax.num = 0; // not necessary, but avoids a lint warning
		bluemax.den = -1; // illegal
		redmin.den = -1; // illegal

		if (isemptygame(g)) {
			Bestred = -1;
			Bestblue = -1;
			return;
		}
		i = 0;
		while (g.edge[i * 4 + 0] != -1) {
			if (g.edge[i * 4 + 0] >= 0) {
				newg = new game(g);
				cutedge(i, newg);
				newvalue = calcgamevalue(newg);
				switch (g.edge[i * 4 + 2]) {
					case 1:// HACKBLUE: 
						if (bluemax.den == -1) {
							bluemax = newvalue;
							bestblue[0] = i;
							bbcnt = 1;
						} else if (uniformplay == 0 &&
									bluemax.num == newvalue.num &&
									bluemax.den == newvalue.den) {
							bestblue[bbcnt++] = i;
						} else if (surlessthan(bluemax, newvalue)) {
							bluemax = newvalue;
							bestblue[0] = i;
							bbcnt = 1;
						}
						break;
					case 2:// HACKRED:
						if (redmin.den == -1) {
							redmin = newvalue;
							bestred[0] = i;
							brcnt = 1;
						} else if (uniformplay == 0 &&
									newvalue.num == redmin.num &&
									newvalue.den == redmin.den) {
							bestred[brcnt++] = i;
						} else if (surlessthan(newvalue, redmin)) {
							redmin = newvalue;
							bestred[0] = i;
							brcnt = 1;
						}
						break;
				}
			}
			i++;
		}
		if (bluemax.den == -1) {
			bluemax.den = 1;
			bluemax.num = -10000;
		}
		if (redmin.den == -1) {
			redmin.den = 1;
			redmin.num = 10000;
		}
		//surmiddle(&bluemax, &redmin, value);
		if (true) {
			if (brcnt == 0) Bestred = -1;
			else Bestred = bestred[rand(brcnt)];
			
			if (bbcnt == 0) Bestblue = -1;
			else Bestblue = bestblue[rand(bbcnt)];
		}
	}
	
	public static void initgame() {
		Hackenbush.edgecount = 0;
		node = new int[128, 64];
		mark = new int[128];
		componentlist = new int[MAXEDGES, MAXEDGES];
		componentvalues = new surreal[MAXEDGES];
		Bestred = 0;
		Bestblue = 0;
		
		// TODO
		// inithashtable();
	}
	
	static int rand(int upper) {
		return (int)(GD.Randi() % upper);
	}
	
	 void reportgamevalue(game G) {
		Value = calcgamevalue(G);
	}

	 void makebluemove(int move, game G) {
		cutedge(move, G);
		Value = calcgamevalue(G);
	}

	public int getbestmove(game G, int color) {
		surreal val;
		int bestmove;
		
		val = calcgamevalue(G);
		findbestgamemoves(G);
		if (color == HACKRED)
			cutedge(bestmove = Bestred, G);
		else
			cutedge(bestmove = Bestblue, G);
		val = calcgamevalue(G);
		Value = val;
		findbestgamemoves(G);
		return bestmove;
	}
}
